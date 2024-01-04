extension Optional: CasePathable {
  @dynamicMemberLookup
  public struct AllCasePaths {
    public var none: AnyCasePath<Optional, Void> {
      AnyCasePath(
        embed: { .none },
        extract: {
          guard case .none = $0 else { return nil }
          return ()
        }
      )
    }

    public var some: AnyCasePath<Optional, Wrapped> {
      AnyCasePath(
        embed: { .some($0) },
        extract: {
          guard case let .some(value) = $0 else { return nil }
          return value
        }
      )
    }

    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Wrapped.AllCasePaths, AnyCasePath<Wrapped, Member>>
    ) -> AnyCasePath<Optional, Member>
    where Wrapped: CasePathable {
      let casePath = Wrapped.allCasePaths[keyPath: keyPath]
      return AnyCasePath(
        embed: { .some(casePath.embed($0)) },
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
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, Member?>>
  ) -> Case<Member>
  where Value: CasePathable {
    self[dynamicMember: keyPath].some
  }
}
