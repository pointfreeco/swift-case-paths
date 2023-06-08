import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct CasePaths2Plugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    CasePathableMacro.self,
    CasePathMacro.self,
  ]
}
