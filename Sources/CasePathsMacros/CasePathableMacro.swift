import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CasePathableMacro {}

extension CasePathableMacro: ConformanceMacro {
  public static func expansion<
    Declaration: DeclGroupSyntax,
    Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    providingConformancesOf declaration: Declaration,
    in context: Context
  ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
    [("CasePathable", nil)]
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
      throw DiagnosticsError(diagnostics: [
        CasePathableMacroDiagnostic.notAnEnum(declaration).diagnose(at: Syntax(node))
      ])
    }

    let access = enumDecl.modifiers?.first(where: \.isNeededAccessLevelModifier)

    let caseDecls = enumDecl.memberBlock
      .members
      .compactMap { $0.decl.as(EnumCaseDeclSyntax.self)?.elements.first }

    let properties: [DeclSyntax] = caseDecls.map { enumCase in
      enumCase.associatedValue.map { associatedValue in
        """
        \(access)var \(raw: enumCase.identifier): \(associatedValue)? {
          if case let .\(raw: enumCase.identifier)(value) = self { value } else { nil }
        }
        """
      }
        ?? """
        \(access)var \(raw: enumCase.identifier): Void? {
          if case .\(raw: enumCase.identifier) = self { () } else { nil }
        }
        """
    }

    return properties
  }
}

enum CasePathableMacroDiagnostic {
  case notAnEnum(DeclGroupSyntax)
}

extension CasePathableMacroDiagnostic: DiagnosticMessage {
  var message: String {
    switch self {
    case let .notAnEnum(decl):
      return """
        @CasePathable macro requires \(decl.identifierDescription.map { "'\($0)' to be " } ?? "")\
        an enum
        """
    }
  }

  var diagnosticID: MessageID {
    switch self {
    case .notAnEnum:
      return MessageID(domain: "MetaEnumDiagnostic", id: "notAnEnum")
    }
  }

  var severity: DiagnosticSeverity {
    switch self {
    case .notAnEnum:
      return .error
    }
  }

  func diagnose(at node: Syntax) -> Diagnostic {
    Diagnostic(node: node, message: self)
  }
}

extension DeclGroupSyntax {
  var identifierDescription: String? {
    switch self {
    case let syntax as ActorDeclSyntax:
      return syntax.identifier.trimmedDescription
    case let syntax as ClassDeclSyntax:
      return syntax.identifier.trimmedDescription
    case let syntax as ExtensionDeclSyntax:
      return syntax.extendedType.trimmedDescription
    case let syntax as ProtocolDeclSyntax:
      return syntax.identifier.trimmedDescription
    case let syntax as StructDeclSyntax:
      return syntax.identifier.trimmedDescription
    case let syntax as EnumDeclSyntax:
      return syntax.identifier.trimmedDescription
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

extension SyntaxStringInterpolation {
  mutating func appendInterpolation<Node: SyntaxProtocol>(_ node: Node?) {
    if let node {
      self.appendInterpolation(node)
    }
  }
}
