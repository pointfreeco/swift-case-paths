extension Result: CasePathable, CasePathIterable {
  public struct AllCasePaths: CasePathReflectable, Sendable {
    public static func _case(for root: Result) -> PartialCaseKeyPath<Result> {
      switch root {
      case .success: return \.success
      case .failure: return \.failure
      }
    }

    public static var _allCaseKeyPaths: [PartialCaseKeyPath<Result>] {
      [\.success, \.failure]
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
  @available(*, deprecated, message: "Iterate over 'Array(Result.allCasePaths)' instead")
  public func makeIterator() -> IndexingIterator<[PartialCaseKeyPath<Result>]> {
    Self._allCaseKeyPaths.makeIterator()
  }
}
