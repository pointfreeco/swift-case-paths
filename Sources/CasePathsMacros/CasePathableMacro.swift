import CasePathsMacrosSupport
import SwiftSyntax
import SwiftSyntaxMacros

public enum CasePathableMacro {}

extension CasePathableMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    try CasePathsMacrosSupport.CasePathableMacro.expansion(
      of: node,
      attachedTo: declaration,
      providingExtensionsOf: type,
      conformingTo: protocols,
      in: context
    )
  }
}

extension CasePathableMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    try CasePathsMacrosSupport.CasePathableMacro.expansion(
      of: node,
      providingMembersOf: declaration,
      in: context
    )
  }
}
