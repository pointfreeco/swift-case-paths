import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct CasePathsPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    CasePathableMacro.self
  ]
}
