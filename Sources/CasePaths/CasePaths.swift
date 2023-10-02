extension AnyCasePath where Root == Value {
  /// The identity case path for `Root`: a case path that always successfully extracts a root value.
  public static var `self`: Self {
    .init(
      embed: { $0 },
      extract: Optional.some
    )
  }
}

extension AnyCasePath where Root: _OptionalProtocol, Value == Root.Wrapped {
  /// The optional case path: a case path that unwraps an optional value.
  public static var some: Self {
    .init(embed: Root.init, extract: { $0.optional })
  }
}

extension AnyCasePath where Root == Void {
  /// Returns a case path that always successfully extracts the given constant value.
  ///
  /// - Parameter value: A constant value.
  /// - Returns: A case path from `()` to `value`.
  public static func constant(_ value: Value) -> Self {
    .init(
      embed: { _ in () },
      extract: { .some(value) }
    )
  }
}

extension AnyCasePath where Value == Never {
  /// The never case path for `Root`: a case path that always fails to extract the a value of the
  /// uninhabited `Never` type.
  public static var never: Self {
    func absurd<A>(_ never: Never) -> A {}
    return .init(
      embed: absurd,
      extract: { _ in nil }
    )
  }
}

extension AnyCasePath where Value: RawRepresentable, Root == Value.RawValue {
  /// Returns a case path for `RawRepresentable` types: a case path that attempts to extract a value
  /// that can be represented by a raw value from a raw value.
  public static var rawValue: Self {
    .init(
      embed: { $0.rawValue },
      extract: Value.init(rawValue:)
    )
  }
}

extension AnyCasePath where Value: LosslessStringConvertible, Root == String {
  /// Returns a case path for `LosslessStringConvertible` types: a case path that attempts to
  /// extract a value that can be represented by a lossless string from a string.
  public static var description: Self {
    .init(
      embed: { $0.description },
      extract: Value.init
    )
  }
}

public protocol _OptionalProtocol {
  associatedtype Wrapped
  var optional: Wrapped? { get }
  init(_ some: Wrapped)
}

extension Optional: _OptionalProtocol {
  public var optional: Wrapped? { self }
}
