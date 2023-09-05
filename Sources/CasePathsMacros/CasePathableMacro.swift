import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CasePathableMacro {
}

extension CasePathableMacro: ExtensionMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
    conformingTo protocols: [SwiftSyntax.TypeSyntax],
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    //if protocols.isEmpty {
    //  return []
    //}
    let ext: DeclSyntax =
      """
      extension \(type.trimmed): CasePaths.CasePathable {}
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

    let enumCaseDecls = enumDecl.memberBlock
      .members
      .compactMap { $0.decl.as(EnumCaseDeclSyntax.self)?.elements.first }

    var seenCaseNames: Set<String> = []
    for enumCaseDecl in enumCaseDecls {
      let name = enumCaseDecl.name.text
      if seenCaseNames.contains(name) {
        throw DiagnosticsError(
          diagnostics: [
            CasePathableMacroDiagnostic.overloadedCaseName(name).diagnose(at: Syntax(enumCaseDecl))
          ]
        )
      }
      seenCaseNames.insert(name)
    }

    let casePaths: [DeclSyntax] = enumCaseDecls.map { enumCaseDecl in
      let caseName = enumCaseDecl.name.trimmed
      let associatedValueName = enumCaseDecl.trimmedTypeDescription
      let hasPayload = enumCaseDecl.parameterClause.map { !$0.parameters.isEmpty } ?? false
      let embedNames: String
      let bindingNames: String
      let returnName: String
      if hasPayload, let associatedValue = enumCaseDecl.parameterClause {
        embedNames =
          "("
        + associatedValue.parameters.enumerated()
          .map { offset, parameter in
            "\(parameter.firstName.map { "\($0): " } ?? "")$\(offset)"
          }
          .joined(separator: ", ")
          + ")"
        let parameterNames = (0..<associatedValue.parameters.count)
          .map { "v\($0)" }
          .joined(separator: ", ")
        bindingNames = "(\(parameterNames))"
        returnName = associatedValue.parameters.count == 1 ? parameterNames : bindingNames
      } else {
        embedNames = ""
        bindingNames = ""
        returnName = "()"
      }

      return """
        \(access)var \(caseName): CasePaths.CasePath<\(enumName), \(raw: associatedValueName)> {\
        CasePaths.CasePath<\(enumName), \(raw: associatedValueName)>._init(
        embed: {\
        .\(caseName)\(raw: embedNames)\
        },
        extract: {\
        guard case\(raw: hasPayload ? " let" : "").\(caseName)\(raw: bindingNames) = $0 else {\
        return nil\
        }\
        return \(raw: returnName)\
        },
        keyPath: \\.\(caseName)
        )\
        }
        """
    }

    //let elements = enumCaseDecls
    //  .map { enumCaseDecl in "      self.\(enumCaseDecl.name.trimmed)" }
    //  .joined(separator: ",\n")

    let properties: [DeclSyntax] = enumCaseDecls.map { enumCaseDecl in
      let caseName = enumCaseDecl.name.trimmed
      let associatedValueName = enumCaseDecl.trimmedTypeDescription
      return """
        \(access)var \(caseName): \(raw: associatedValueName)? { \
        Self.allCasePaths.\(caseName).extract(from: self) \
        }
        """
    }

    return [
      """
      \(access)struct AllCasePaths { \
      \(raw: casePaths.map(\.description).joined(separator: "\n")) \
      }
      \(access)static var allCasePaths: AllCasePaths { \
      AllCasePaths() \
      }
      \(raw: properties.map(\.description).joined(separator: "\n"))
      """
    ]
    //return [
    //  """
    //  \(access)struct AllCasePaths: CasePaths.CasePathIterable {
    //  \(raw: casePaths.map(\.description).joined(separator: "\n"))
    //    \(access)var _$elements: [any PartialCasePath<\(enumName)>] {
    //      [
    //  \(raw: elements)
    //      ]
    //    }
    //  }
    //  \(access)static var allCasePaths: AllCasePaths {
    //    AllCasePaths()
    //  }
    //  \(raw: properties.map(\.description).joined(separator: "\n"))
    //  """
    //]
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
        @CasePathable macro requires \(decl.nameDescription.map { "'\($0)' to be " } ?? "")an enum
        """
    case let .overloadedCaseName(name):
      return """
        @CasePathable macro does not allow duplicate case name '\(name)'
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
