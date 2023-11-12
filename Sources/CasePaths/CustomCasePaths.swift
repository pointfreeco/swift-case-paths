extension AnyCasePath where Root == Value {
  #if swift(>=5.9)
    @available(iOS, deprecated: 9999, message: "Use the '\\.self' case key path, instead")
    @available(macOS, deprecated: 9999, message: "Use the '\\.self' case key path, instead")
    @available(tvOS, deprecated: 9999, message: "Use the '\\.self' case key path, instead")
    @available(watchOS, deprecated: 9999, message: "Use the '\\.self' case key path, instead")
    public static var `self`: Self {
      .init(
        embed: { $0 },
        extract: Optional.some
      )
    }
  #else
    /// The identity case path for `Root`: a case path that always successfully extracts a root
    /// value.
    public static var `self`: Self {
      .init(
        embed: { $0 },
        extract: Optional.some
      )
    }
  #endif
}

extension AnyCasePath where Root: _OptionalProtocol, Value == Root.Wrapped {
  #if swift(>=5.9)
    @available(
      iOS, deprecated: 9999, message: "Use the '\\Optional.Cases.some' case key path, instead"
    )
    @available(
      macOS, deprecated: 9999, message: "Use the '\\Optional.Cases.some' case key path, instead"
    )
    @available(
      tvOS, deprecated: 9999, message: "Use the '\\Optional.Cases.some' case key path, instead"
    )
    @available(
      watchOS, deprecated: 9999, message: "Use the '\\Optional.Cases.some' case key path, instead"
    )
    public static var some: Self {
      .init(embed: Root.init, extract: { $0.optional })
    }
  #else
    /// The optional case path: a case path that unwraps an optional value.
    public static var some: Self {
      .init(embed: Root.init, extract: { $0.optional })
    }
  #endif
}

public protocol _OptionalProtocol {
  associatedtype Wrapped
  var optional: Wrapped? { get }
  init(_ some: Wrapped)
}

extension Optional: _OptionalProtocol {
  public var optional: Wrapped? { self }
}
