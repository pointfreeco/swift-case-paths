import SwiftSyntax

var nonisolated: TokenSyntax? {
  #if compiler(>=6.1)
    .keyword(.nonisolated, trailingTrivia: .space)
  #else
    nil
  #endif
}
