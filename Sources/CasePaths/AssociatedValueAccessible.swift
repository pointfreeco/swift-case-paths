/// Add this protocol to enum for access to it's associated values over subscription with CasePath.
///
/// ```swift
/// enum Foo: AssociatedValueAccessible {
///   case bar(Int)
/// }
///
/// let foo = Foo.bar(42)
/// let value = foo[/Foo.bar] // Optional<Int>(42)
///
/// var foo = Foo.bar(42)
/// foo[/Foo.bar] = 84
/// let value = foo[/Foo.bar] // Optional<Int>(84)
/// ```
public protocol AssociatedValueAccessible {}

public extension AssociatedValueAccessible {
  subscript<Value>(_ casePath: CasePath<Self, Value>) -> Value? {
    get {
      casePath.extract(from: self)
    }
    set {
      if let value = newValue {
        self = casePath.embed(value)
      }
    }
  }
}
