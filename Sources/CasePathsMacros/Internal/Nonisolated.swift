#if canImport(SwiftSyntax600)
  import SwiftSyntax
#else
  @preconcurrency import SwiftSyntax
#endif

#if compiler(>=6.1)
  let nonisolated: TokenSyntax? = .keyword(.nonisolated, trailingTrivia: .space)
#else
  let nonisolated: TokenSyntax? = nil
#endif
