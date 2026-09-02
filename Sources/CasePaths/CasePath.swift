@_documentation(visibility: private)
public protocol CasePath<Root, Value> {
  associatedtype Root
  associatedtype Value
  func embed(_ value: Value) -> Root
  func extract(from root: Root) -> Value?
}

extension AnyCasePath: CasePath {}
