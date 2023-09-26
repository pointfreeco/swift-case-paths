extension CasePath where Root == Value {
  /// The identity case path for `Root`: a case path that always successfully extracts a root value.
  @available(
    iOS,
    deprecated: 9999,
    message: "Use '#casePath(\\.self)' with a '@CasePathable' enum instead"
  )
  @available(
    macOS,
    deprecated: 9999,
    message: "Use '#casePath(\\.self)' with a '@CasePathable' enum instead"
  )
  @available(
    tvOS,
    deprecated: 9999,
    message: "Use '#casePath(\\.self)' with a '@CasePathable' enum instead"
  )
  @available(
    watchOS,
    deprecated: 9999,
    message: "Use '#casePath(\\.self)' with a '@CasePathable' enum instead"
  )
  public static var `self`: CasePath {
    .init(
      embed: { $0 },
      extract: Optional.some,
      keyPaths: []
    )
  }
}

extension CasePath where Root: _OptionalProtocol, Value == Root.Wrapped {
  /// The optional case path: a case path that unwraps an optional value.
  @available(*, deprecated)
  public static var some: CasePath {
    .init(embed: Root.init, extract: { $0._wrapped })
  }
}

extension CasePath where Root == Void {
  /// Returns a case path that always successfully extracts the given constant value.
  ///
  /// - Parameter value: A constant value.
  /// - Returns: A case path from `()` to `value`.
  @available(*, deprecated)
  public static func constant(_ value: Value) -> CasePath {
    .init(
      embed: { _ in () },
      extract: { .some(value) }
    )
  }
}

extension CasePath where Value == Never {
  /// The never case path for `Root`: a case path that always fails to extract the a value of the
  /// uninhabited `Never` type.
  @available(*, deprecated)
  public static var never: CasePath {
    func absurd<A>(_ never: Never) -> A {}
    return .init(
      embed: absurd,
      extract: { _ in nil }
    )
  }
}

extension CasePath where Value: RawRepresentable, Root == Value.RawValue {
  /// Returns a case path for `RawRepresentable` types: a case path that attempts to extract a value
  /// that can be represented by a raw value from a raw value.
  @available(*, deprecated)
  public static var rawValue: CasePath {
    .init(
      embed: { $0.rawValue },
      extract: Value.init(rawValue:)
    )
  }
}

extension CasePath where Value: LosslessStringConvertible, Root == String {
  /// Returns a case path for `LosslessStringConvertible` types: a case path that attempts to
  /// extract a value that can be represented by a lossless string from a string.
  @available(*, deprecated)
  public static var description: CasePath {
    .init(
      embed: { $0.description },
      extract: Value.init
    )
  }
}

public protocol _OptionalProtocol {
  associatedtype Wrapped
  var _wrapped: Wrapped? { get }
  init(_ some: Wrapped)
}

extension Optional: _OptionalProtocol {
  public var _wrapped: Wrapped? { self }
}