extension Optional: CasePathable {
  public struct AllCasePaths: CasePath, Hashable, Sendable {
    public func embed(_ value: Optional) -> Optional { value }

    public func extract(from root: Optional) -> Optional? { root }

    @frozen
    public struct _$none: CasePath, Hashable, Sendable {
      @inlinable
      public init() {}

      @inlinable
      public func embed(_ value: Void) -> Optional { .none }

      @inlinable
      public func extract(from root: Optional) -> Void? {
        guard case .none = root else { return nil }
        return ()
      }
    }

    /// A case path to the absence of a value.
    public var none: _$none { _$none() }

    @frozen
    public struct _$some: CasePath, Hashable, Sendable {
      @inlinable
      public init() {}

      @inlinable
      public func embed(_ value: Wrapped) -> Optional { .some(value) }

      @inlinable
      public func extract(from root: Optional) -> Wrapped? {
        guard case .some(let value) = root else { return nil }
        return value
      }
    }

    /// A case path to the presence of a value.
    public var some: _$some { _$some() }
  }

  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public var `case`: PartialCaseKeyPath<Optional> {
    switch self {
    case .none: return \.none
    case .some: return \.some
    }
  }

  public static var _allCaseKeyPaths: [PartialCaseKeyPath<Optional>] {
    [\.none, \.some]
  }

  public static func caseName(for keyPath: PartialCaseKeyPath<Self>) -> String? {
    switch keyPath {
    case \.none: return "none"
    case \.some: return "some"
    default: return nil
    }
  }
}

extension Optional.AllCasePaths: Sequence {
  public func makeIterator() -> some IteratorProtocol<PartialCaseKeyPath<Optional>> {
    [\.none, \.some].makeIterator()
  }
}

extension Optional where Wrapped: CasePathable {
  @_disfavoredOverload
  public func `is`(_ keyPath: PartialCaseKeyPath<Wrapped>) -> Bool {
    self?[case: keyPath] != nil
  }

  @_disfavoredOverload
  public mutating func modify<Path, Result>(
    _ keyPath: CaseKeyPath<Wrapped, Path>,
    _ body: (inout Path.Value) throws -> Result
  ) throws -> Result {
    let path = Wrapped.allCasePaths[keyPath: keyPath]
    guard case .some(var wrapped) = self, var value = path.extract(from: wrapped)
    else {
      throw CasePathMismatch()
    }
    let result = try body(&value)
    self = .some(path.embed(value))
    return result
  }
}
