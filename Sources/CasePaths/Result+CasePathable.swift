extension Result: CasePathable, CasePathIterable {
  public struct AllCasePaths: RandomAccessCollection {
    public var success: AnyCasePath<Result, Success> {
      AnyCasePath(
        embed: { .success($0) },
        extract: {
          guard case let .success(value) = $0 else { return nil }
          return value
        }
      )
    }

    public var failure: AnyCasePath<Result, Failure> {
      AnyCasePath(
        embed: { .failure($0) },
        extract: {
          guard case let .failure(value) = $0 else { return nil }
          return value
        }
      )
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { 2 }
    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }
    public subscript(position: Int) -> PartialCaseKeyPath<Result> {
      switch position {
      case 0: return \Result.Cases.success
      case 1: return \Result.Cases.failure
      default: fatalError("Index out of range")
      }
    }
  }

  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }
}
