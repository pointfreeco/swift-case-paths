import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct CasePathsPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    CasePathableMacro.self
  ]
}
