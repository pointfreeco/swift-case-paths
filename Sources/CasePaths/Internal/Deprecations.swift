// NB: Deprecated after 1.0.0

@available(*, deprecated, message: "Use 'CustomDebugStringConvertible.debugDescription' instead")
extension CasePath: CustomStringConvertible {
  public var description: String {
    "CasePath<\(typeName(Root.self)), \(typeName(Value.self))>"
  }
}
