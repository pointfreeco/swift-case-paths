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
        where: { Self.conformanceNames.contains($0.type.trimmedDescription) }
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

    let rewriter = SelfRewriter(selfEquivalent: enumName)
    let memberBlock = rewriter.rewrite(enumDecl.memberBlock).cast(MemberBlockSyntax.self)

    let enumCaseDecls = memberBlock
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

    let casePaths = generateDeclSyntax(from: memberBlock.members, with: access, enumName: enumName)

    return [
      """
      \(access)struct AllCasePaths {
      \(raw: casePaths.map(\.description).joined(separator: "\n"))
      }
      \(access)static var allCasePaths: AllCasePaths { AllCasePaths() }
      """
    ]
  }

  static func generateDeclSyntax(
    from elements: MemberBlockItemListSyntax,
    with access: DeclModifierListSyntax.Element?,
    enumName: TokenSyntax
  ) -> [DeclSyntax] {
    elements.flatMap {
      if let elements = $0.decl.as(EnumCaseDeclSyntax.self)?.elements {
        return generateDeclSyntax(from: elements, with: access, enumName: enumName)
      }
      if let ifConfigDecl = $0.decl.as(IfConfigDeclSyntax.self) {
        let ifClauses = ifConfigDecl.clauses.flatMap { decl -> [DeclSyntax] in
          guard let elements = decl.elements?.as(MemberBlockItemListSyntax.self) else {
            return []
          }
          let title = "\(decl.poundKeyword.text) \(decl.condition?.description ?? "")"
          return ["\(raw: title)"] + generateDeclSyntax(from: elements, with: access, enumName: enumName)
        }
        return ifClauses + ["#endif"]
      }
      return []
    }
  }

  static func generateDeclSyntax(
    from enumCaseDecls: EnumCaseElementListSyntax,
    with access: DeclModifierListSyntax.Element?,
    enumName: TokenSyntax
  ) -> [DeclSyntax] {
    enumCaseDecls.map {
      let caseName = $0.name.trimmed
      let associatedValueName = $0.trimmedTypeDescription
      let hasPayload = $0.parameterClause.map { !$0.parameters.isEmpty } ?? false
      let bindingNames: String
      let returnName: String
      if hasPayload, let associatedValue = $0.parameterClause {
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
        \(raw: qualifiedCasePathTypeName)<\(enumName), \(raw: associatedValueName)> {
        \(raw: qualifiedCasePathTypeName)<\(enumName), \(raw: associatedValueName)>(
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
    case .keyword(.package): return true
    default: return false
    }
  }
}

extension EnumCaseElementListSyntax.Element {
  var trimmedTypeDescription: String {
    if var associatedValue = self.parameterClause, !associatedValue.parameters.isEmpty {
      if associatedValue.parameters.count == 1,
        let type = associatedValue.parameters.first?.type.trimmed
      {
        return type.is(SomeOrAnyTypeSyntax.self)
          ? "(\(type))"
          : "\(type)"
      } else {
        for index in associatedValue.parameters.indices {
          associatedValue.parameters[index].type.trailingTrivia = ""
          associatedValue.parameters[index].defaultValue = nil
          if associatedValue.parameters[index].firstName?.tokenKind == .wildcard {
            associatedValue.parameters[index].colon = nil
            associatedValue.parameters[index].firstName = nil
            associatedValue.parameters[index].secondName = nil
          }
        }
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

final class SelfRewriter: SyntaxRewriter {
  let selfEquivalent: TokenSyntax

  init(selfEquivalent: TokenSyntax) {
    self.selfEquivalent = selfEquivalent
  }

  override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
    guard node.name.text == "Self"
    else { return super.visit(node) }
    return super.visit(node.with(\.name, self.selfEquivalent))
  }
}
