extension Optional: CasePathable {
  @dynamicMemberLookup
  public struct AllCasePaths: Sendable {
    /// Returns the case key path for a given root value.
//    public subscript(root: Optional) -> PartialCaseKeyPath<Optional> {
//      switch root {
//      case .none: return \.none
//      case .some: return \.some
//      }
//    }

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
  #if swift(>=6)
    /// A case path to the presence of a nested value.
    ///
    /// This subscript can chain into an optional's wrapped value without explicitly specifying each
    /// `some` component.
    @_disfavoredOverload
    public subscript<Member>(
      dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, Member?>> & Sendable
    ) -> Case<Member>
    where Value: CasePathable {
      self[dynamicMember: keyPath].some
    }
  #else
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
  #endif
}

extension Optional.AllCasePaths: Sequence {
  public func makeIterator() -> some IteratorProtocol<PartialCaseKeyPath<Optional>> {
    [\.none, \.some].makeIterator()
  }
}
