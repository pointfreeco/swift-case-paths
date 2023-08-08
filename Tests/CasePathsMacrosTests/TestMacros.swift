import CasePathsMacros
import SwiftSyntaxMacros

let testMacros: [String: Macro.Type] = [
  "CasePathable": CasePathableMacro.self,
  "casePath": CasePathMacro.self,
]
