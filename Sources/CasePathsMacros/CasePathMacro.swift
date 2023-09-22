import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct CasePathMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> ExprSyntax {
    guard let argument = node.argumentList.first?.expression.as(KeyPathExprSyntax.self)
    else {
      throw CustomError.message("#casePath requires a @CasePathable enum key path")
    }

    var path = ""
    for (offset, component) in argument.components.enumerated() {
      if offset.isMultiple(of: 2),
        component.period != nil,
        let identifier = component.component.as(KeyPathPropertyComponentSyntax.self)?.declName
      {
        if offset == 0 {
          let typeName = argument.root.map { "\($0).AllCasePaths" } ?? ""
          path.append(
            "CasePaths.CasePath._$case(\\\(typeName).\(identifier.trimmedDescription))"
          )
        } else {
          path.append(".appending(path: ._$case(\\.\(identifier.trimmedDescription)))")
        }
      } else if component.component.is(KeyPathOptionalComponentSyntax.self) {
        continue
      } else {
        throw CustomError.message("#casePath requires a @CasePathable enum key path")
      }
    }

    return "\(raw: path)"
  }
}

enum CustomError: Error, CustomStringConvertible {
  case message(String)

  var description: String {
    switch self {
    case .message(let text):
      return text
    }
  }
}
