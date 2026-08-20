import IssueReporting

extension Optional: CasePathable {
  public struct AllCasePaths: CasePathReflectable, Hashable, Sendable {
    public func embed(_ value: Optional) -> Optional { value }

    public func extract(from root: Optional) -> Optional? { root }

    public subscript(root: Optional) -> PartialCaseKeyPath<Optional> {
      switch root {
      case .none: return \.none
      case .some: return \.some
      }
    }

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
  public mutating func modify<Path>(
    _ keyPath: CaseKeyPath<Wrapped, Path>,
    yield: (inout Path.Value) -> Void,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    let path = Wrapped.allCasePaths[keyPath: keyPath]
    guard case .some(let wrapped) = self, var value = path.extract(from: wrapped)
    else {
      reportIssue(
        """
        Can't modify '\(String(describing: self))' via \
        'CaseKeyPath<\(Self.self), \(Path.Value.self)>' \
        (aka '\(String(reflecting: keyPath))')
        """,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
      return
    }
    yield(&value)
    self = .some(path.embed(value))
  }
}
