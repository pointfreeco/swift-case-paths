extension CasePath where Root == Value {
  /// The identity case path for `Root`: a case path that always successfully extracts a root value.
  public static var `self`: CasePath {
    .init(
      embed: { $0 },
      extract: Optional.some
    )
  }
}

extension CasePath where Root: _OptionalProtocol, Value == Root.Wrapped {
  /// The optional case path: a case path that unwraps an optional value.
  public static var some: CasePath {
    .init(embed: Root.init, extract: { $0.optional })
  }
}

extension CasePath where Root == Void {
  /// Returns a case path that always successfully extracts the given constant value.
  ///
  /// - Parameter value: A constant value.
  /// - Returns: A case path from `()` to `value`.
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
  public static var description: CasePath {
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

/// A protocol that represents types from which values can be extracted using a `CasePath`.
public protocol Extractable {}

/// A protocol that represents types into which values can be embedded using a `CasePath`.
public protocol Embeddable {}

public extension Extractable {
  /// Returns the value extracted using the given `CasePath`, or `nil` if the extraction fails.
  ///
  /// - Parameter casePath: The `CasePath` to use for extraction.
  /// - Returns: The value extracted using the given `CasePath`, or `nil` if the extraction fails.
  subscript<Value>(casePath path: CasePath<Self, Value>) -> Value? {
    path.extract(from: self)
  }
}

public extension Embeddable {
  /// Returns the value extracted using the given `CasePath`, or `nil` if the extraction fails.
  ///
  /// If the given value is not `nil`, the `CasePath` is used to embed the value.
  ///
  /// - Parameter casePath: The `CasePath` to use for extraction and embedding.
  /// - Returns: The value extracted using the given `CasePath`, or `nil` if the extraction fails.
  subscript<Value>(casePath path: CasePath<Self, Value>) -> Value? {
    get { path.extract(from: self) }
    set {
      if let newValue = newValue {
        self = path.embed(newValue)
      }
    }
  }
}
