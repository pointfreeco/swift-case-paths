import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CasePathableMacro {
  static let moduleName = "CasePaths"
  static let conformanceName = "CasePathable"
  static var qualifiedConformanceName: String { "\(Self.moduleName).\(Self.conformanceName)" }
  static var conformanceNames: [String] { [Self.conformanceName, Self.qualifiedConformanceName] }
  static let casePathTypeName = "AnyCasePath"
  static var qualifiedCasePathTypeName: String { "\(Self.moduleName).\(Self.casePathTypeName)" }
  static var qualifiedCaseTypeName: String { "\(Self.moduleName).Case" }
}

extension CasePathableMacro: ExtensionMacro {
  public static func expansion<D: DeclGroupSyntax, T: TypeSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    attachedTo declaration: D,
    providingExtensionsOf type: T,
    conformingTo protocols: [TypeSyntax],
    in context: C
  ) throws -> [ExtensionDeclSyntax] {
    // if protocols.isEmpty {
    //   return []
    // }
    guard let enumDecl = declaration.as(EnumDeclSyntax.self)
    else {
      // TODO: Diagnostic?
      return []
    }
    if let inheritanceClause = enumDecl.inheritanceClause,
      inheritanceClause.inheritedTypes.contains(
        where: { Self.conformanceNames.contains($0.trimmedDescription) }
      )
    {
      return []
    }
    let ext: DeclSyntax =
      """
      extension \(type.trimmed): \(raw: Self.qualifiedConformanceName) {}
      """
    return [ext.cast(ExtensionDeclSyntax.self)]
  }
}

extension CasePathableMacro: MemberMacro {
  public static func expansion<
    Declaration: DeclGroupSyntax, Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    providingMembersOf declaration: Declaration,
    in context: Context
  ) throws -> [DeclSyntax] {

    let withGetters: Bool
    switch node.arguments {
    case let .argumentList(list):
      withGetters =
        list
        .first(where: { $0.label?.text == "withGetters" })?
        .expression
        .as(BooleanLiteralExprSyntax.self)?
        .literal
        .text != "false"
    default:
      withGetters = true
    }

    guard let enumDecl = declaration.as(EnumDeclSyntax.self)
    else {
      throw DiagnosticsError(
        diagnostics: [
          CasePathableMacroDiagnostic
            .notAnEnum(declaration)
            .diagnose(at: declaration.keyword)
        ]
      )
    }
    let enumName = enumDecl.name.trimmed

    let access = enumDecl.modifiers.first(where: \.isNeededAccessLevelModifier)

    let enumCaseDecls = enumDecl.memberBlock
      .members
      .flatMap { $0.decl.as(EnumCaseDeclSyntax.self)?.elements ?? [] }

    var seenCaseNames: Set<String> = []
    for enumCaseDecl in enumCaseDecls {
      let name = enumCaseDecl.name.text
      if seenCaseNames.contains(name) {
        throw DiagnosticsError(
          diagnostics: [
            CasePathableMacroDiagnostic.overloadedCaseName(name).diagnose(
              at: Syntax(enumCaseDecl.name))
          ]
        )
      }
      seenCaseNames.insert(name)
    }

    let casePaths: [DeclSyntax] = enumCaseDecls.map { enumCaseDecl in
      let caseName = enumCaseDecl.name.trimmed
      let associatedValueName = enumCaseDecl.trimmedTypeDescription
      let hasPayload = enumCaseDecl.parameterClause.map { !$0.parameters.isEmpty } ?? false
      let bindingNames: String
      let returnName: String
      if hasPayload, let associatedValue = enumCaseDecl.parameterClause {
        let parameterNames = (0..<associatedValue.parameters.count)
          .map { "v\($0)" }
          .joined(separator: ", ")
        bindingNames = "(\(parameterNames))"
        returnName = associatedValue.parameters.count == 1 ? parameterNames : bindingNames
      } else {
        bindingNames = ""
        returnName = "()"
      }

      return """
        \(access)var \(caseName): \
        \(raw: Self.qualifiedCasePathTypeName)<\(enumName), \(raw: associatedValueName)> {
        \(raw: Self.qualifiedCasePathTypeName)<\(enumName), \(raw: associatedValueName)>(
        embed: \(raw: hasPayload ? "\(enumName).\(caseName)" : "{ \(enumName).\(caseName) }"),
        extract: {
        guard case\(raw: hasPayload ? " let" : "").\(caseName)\(raw: bindingNames) = $0 else { \
        return nil \
        }
        return \(raw: returnName)
        }
        )
        }
        """
    }

    let properties: [DeclSyntax] =
      withGetters
      ? enumCaseDecls.map { enumCaseDecl in
        let caseName = enumCaseDecl.name.trimmed
        let associatedValueName = enumCaseDecl.trimmedTypeDescription
        return """
          \(access)var \(caseName): \(raw: associatedValueName)? { \
          self[keyPath: \\\(raw: Self.qualifiedCaseTypeName).\(caseName)] \
          }
          """
      }
      : []

    return [
      """
      \(access)struct AllCasePaths {
      \(raw: casePaths.map(\.description).joined(separator: "\n"))
      }
      \(access)static var allCasePaths: AllCasePaths { AllCasePaths() }
      \(raw: properties.map(\.description).joined(separator: "\n"))
      """
    ]
  }
}

enum CasePathableMacroDiagnostic {
  case notAnEnum(DeclGroupSyntax)
  case overloadedCaseName(String)
}

extension CasePathableMacroDiagnostic: DiagnosticMessage {
  var message: String {
    switch self {
    case let .notAnEnum(decl):
      return """
        '@CasePathable' cannot be applied to\
        \(decl.keywordDescription.map { " \($0)" } ?? "") type\
        \(decl.nameDescription.map { " '\($0)'" } ?? "")
        """
    case let .overloadedCaseName(name):
      return """
        '@CasePathable' cannot be applied to overloaded case name '\(name)'
        """
    }
  }

  var diagnosticID: MessageID {
    switch self {
    case .notAnEnum:
      return MessageID(domain: "MetaEnumDiagnostic", id: "notAnEnum")
    case .overloadedCaseName:
      return MessageID(domain: "MetaEnumDiagnostic", id: "overloadedCaseName")
    }
  }

  var severity: DiagnosticSeverity {
    switch self {
    case .notAnEnum:
      return .error
    case .overloadedCaseName:
      return .error
    }
  }

  func diagnose(at node: Syntax) -> Diagnostic {
    Diagnostic(node: node, message: self)
  }
}

extension DeclGroupSyntax {
  var keyword: Syntax {
    switch self {
    case let syntax as ActorDeclSyntax:
      return Syntax(syntax.actorKeyword)
    case let syntax as ClassDeclSyntax:
      return Syntax(syntax.classKeyword)
    case let syntax as ExtensionDeclSyntax:
      return Syntax(syntax.extensionKeyword)
    case let syntax as ProtocolDeclSyntax:
      return Syntax(syntax.protocolKeyword)
    case let syntax as StructDeclSyntax:
      return Syntax(syntax.structKeyword)
    case let syntax as EnumDeclSyntax:
      return Syntax(syntax.enumKeyword)
    default:
      return Syntax(self)
    }
  }

  var keywordDescription: String? {
    switch self {
    case let syntax as ActorDeclSyntax:
      return syntax.actorKeyword.trimmedDescription
    case let syntax as ClassDeclSyntax:
      return syntax.classKeyword.trimmedDescription
    case let syntax as ExtensionDeclSyntax:
      return syntax.extensionKeyword.trimmedDescription
    case let syntax as ProtocolDeclSyntax:
      return syntax.protocolKeyword.trimmedDescription
    case let syntax as StructDeclSyntax:
      return syntax.structKeyword.trimmedDescription
    case let syntax as EnumDeclSyntax:
      return syntax.enumKeyword.trimmedDescription
    default:
      return nil
    }
  }

  var nameDescription: String? {
    switch self {
    case let syntax as ActorDeclSyntax:
      return syntax.name.trimmedDescription
    case let syntax as ClassDeclSyntax:
      return syntax.name.trimmedDescription
    case let syntax as ExtensionDeclSyntax:
      return syntax.extendedType.trimmedDescription
    case let syntax as ProtocolDeclSyntax:
      return syntax.name.trimmedDescription
    case let syntax as StructDeclSyntax:
      return syntax.name.trimmedDescription
    case let syntax as EnumDeclSyntax:
      return syntax.name.trimmedDescription
    default:
      return nil
    }
  }
}

extension DeclModifierSyntax {
  var isNeededAccessLevelModifier: Bool {
    switch self.name.tokenKind {
    case .keyword(.public): return true
    default: return false
    }
  }
}

extension EnumCaseElementListSyntax.Element {
  var trimmedTypeDescription: String {
    if let associatedValue = self.parameterClause, !associatedValue.parameters.isEmpty {
      if associatedValue.parameters.count == 1,
        let type = associatedValue.parameters.first?.type.trimmed
      {
        return type.is(SomeOrAnyTypeSyntax.self)
          ? "(\(type))"
          : "\(type)"
      } else {
        return "(\(associatedValue.parameters.trimmed))"
      }
    } else {
      return "Void"
    }
  }
}

extension SyntaxStringInterpolation {
  mutating func appendInterpolation<Node: SyntaxProtocol>(_ node: Node?) {
    if let node {
      self.appendInterpolation(node)
    }
  }
}
