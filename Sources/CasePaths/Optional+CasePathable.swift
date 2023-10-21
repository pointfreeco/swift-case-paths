extension Optional: CasePathable, CasePathIterable {
  public struct AllCasePaths: RandomAccessCollection {
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

    public var startIndex: Int { 0 }
    public var endIndex: Int { 2 }
    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }
    public subscript(position: Int) -> PartialCaseKeyPath<Optional> {
      switch position {
      case 0: return \Optional.Cases.some
      case 1: return \Optional.Cases.none
      default: fatalError("Index out of range")
      }
    }
  }

  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }
}
