extension OptionalPath where Root == Value {
  /// The identity path for `Root`: an optional path that always successfully extracts a root value.
  @inlinable public class var `self`: Self {
    unsafeDowncast(CasePath<Root, Value>(extract: Optional.some, embed: { $0 }), to: Self.self)
  }
}

extension OptionalPath where Root == Void {
  /// Returns an optional path that always successfully extracts the given constant value.
  ///
  /// - Parameter value: A constant value.
  /// - Returns: An optional path from `()` to `value`.
  @inlinable public class func constant(_ value: Value) -> Self {
    unsafeDowncast(
      CasePath<Root, Value>(extract: { .some(value) }, embed: { _ in () }),
      to: Self.self
    )
  }
}

extension OptionalPath where Value == Never {
  /// The never path for `Root`: an optional path that always fails to extract the a value of the
  /// uninhabited `Never` type.
  @inlinable public static var never: Self {
    func absurd<A>(_ never: Never) -> A {}
    return unsafeDowncast(
      CasePath<Root, Value>(extract: { _ in nil }, embed: absurd),
      to: Self.self
    )
  }
}

extension OptionalPath where Value: RawRepresentable, Root == Value.RawValue {
  /// Returns a path for `RawRepresentable` types: an optional path that attempts to extract a value
  /// that can be represented by a raw value from a raw value.
  @inlinable public static var rawValue: Self {
    unsafeDowncast(
      CasePath<Root, Value>(extract: Value.init(rawValue:), embed: { $0.rawValue }),
      to: Self.self
    )
  }
}

extension OptionalPath where Value: LosslessStringConvertible, Root == String {
  /// Returns a path for `LosslessStringConvertible` types: an optional path that attempts to
  /// extract a value that can be represented by a lossless string from a string.
  @inlinable public static var description: Self {
    unsafeDowncast(
      CasePath<Root, Value>(extract: Value.init, embed: { $0.description }),
      to: Self.self
    )
  }
}
