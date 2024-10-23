// NB: Dynamic member lookup does not currently support sendable key paths and even breaks
//     autocomplete.
//
//     * https://github.com/swiftlang/swift/issues/77035
//     * https://github.com/swiftlang/swift/issues/77105
extension _AppendKeyPath {
  @_transparent
  package func unsafeSendable<Root, Value>() -> any Sendable & KeyPath<Root, Value>
  where Self == KeyPath<Root, Value> {
    #if compiler(>=6)
      unsafeBitCast(self, to: (any Sendable & KeyPath<Root, Value>).self)
    #else
      self
    #endif
  }
}
