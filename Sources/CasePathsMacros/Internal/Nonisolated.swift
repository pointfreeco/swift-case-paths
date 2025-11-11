import SwiftSyntax

#if compiler(>=6.1)
  let nonisolated: TokenSyntax? = .keyword(.nonisolated, trailingTrivia: .space)
#else
  let nonisolated: TokenSyntax? = nil
#endif
