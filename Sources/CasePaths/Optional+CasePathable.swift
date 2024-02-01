extension Optional: CasePathable {
  @dynamicMemberLookup
  public struct AllCasePaths {
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
          guard case let .some(value) = $0 else { return nil }
          return casePath.extract(from: value)
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
