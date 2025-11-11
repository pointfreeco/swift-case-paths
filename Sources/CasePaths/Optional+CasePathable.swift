extension Optional: CasePathable, CasePathIterable {
  @dynamicMemberLookup
  public struct AllCasePaths: CasePathReflectable, Sendable {
    public subscript(root: Optional) -> PartialCaseKeyPath<Optional> {
      switch root {
      case .none: return \.none
      case .some: return \.some
      }
    }

    /// A case path to the absence of a value.
    public var none: AnyCasePath<Optional, Void> {
      AnyCasePath(
        embed: { .none },
        extract: {
          guard case .none = $0 else { return nil }
          return ()
        }
      )
    }

    /// A case path to the presence of a value.
    public var some: AnyCasePath<Optional, Wrapped> {
      AnyCasePath(
        embed: { .some($0) },
        extract: {
          guard case let .some(value) = $0 else { return nil }
          return value
        }
      )
    }

    /// A case path to an optional-chained value.
    @_disfavoredOverload
    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Wrapped.AllCasePaths, AnyCasePath<Wrapped, Member>>
    ) -> AnyCasePath<Optional, Member?>
    where Wrapped: CasePathable {
      let casePath = Wrapped.allCasePaths[keyPath: keyPath]
      return AnyCasePath(
        embed: { $0.map(casePath.embed) },
        extract: {
          guard case let .some(wrapped) = $0, let member = casePath.extract(from: wrapped)
          else { return .none }
          return member
        }
      )
    }
  }

  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }
}

extension Case {
  /// A case path to the presence of a nested value.
  ///
  /// This subscript can chain into an optional's wrapped value without explicitly specifying each
  /// `some` component.
  @_disfavoredOverload
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, Member?>>
  ) -> Case<Member>
  where Value: CasePathable {
    self[dynamicMember: keyPath].some
  }
}

extension Optional.AllCasePaths: Sequence {
  public func makeIterator() -> some IteratorProtocol<PartialCaseKeyPath<Optional>> {
    [\.none, \.some].makeIterator()
  }
}

extension Optional where Wrapped: CasePathable {
  @_disfavoredOverload
  @_documentation(visibility: internal)
  public func `is`(_ keyPath: PartialCaseKeyPath<Wrapped>) -> Bool {
    self?[case: keyPath] != nil
  }

  @_disfavoredOverload
  @_documentation(visibility: internal)
  public mutating func modify<Value>(
    _ keyPath: CaseKeyPath<Wrapped, Value>,
    yield: (inout Value) -> Void,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    modify(
      (\Cases.some).appending(path: keyPath),
      yield: yield,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
}
