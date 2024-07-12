extension Result: CasePathable, CasePathIterable {
  public struct AllCasePaths: CasePathReflectable, Sendable {
    public subscript(root: Result) -> PartialCaseKeyPath<Result> {
      switch root {
      case .success: return \.success
      case .failure: return \.failure
      }
    }

    /// A success case path, for embedding or extracting a `Success` value.
    public var success: AnyCasePath<Result, Success> {
      AnyCasePath(
        embed: { .success($0) },
        extract: {
          guard case let .success(value) = $0 else { return nil }
          return value
        }
      )
    }

    /// A failure case path, for embedding or extracting a `Failure` value.
    public var failure: AnyCasePath<Result, Failure> {
      AnyCasePath(
        embed: { .failure($0) },
        extract: {
          guard case let .failure(value) = $0 else { return nil }
          return value
        }
      )
    }
  }

  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }
}

extension Result.AllCasePaths: Sequence {
  public func makeIterator() -> some IteratorProtocol<PartialCaseKeyPath<Result>> {
    [\.success, \.failure].makeIterator()
  }
}
