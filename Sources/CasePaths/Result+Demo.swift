extension Result: CasePathable {
  public struct AllCasePaths {
    public var success: Case<Result, Success> {
      Case(
        embed: { .success($0) },
        extract: {
          guard case let .success(value) = $0 else { return nil }
          return value
        }
      )
    }
    public var failure: Case<Result, Failure> {
      Case(
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

private func f() {
  var result: Result<String, Error> = .success("Hello, world!")
  let casePath: CasePath<Result<String, Error>, String> = \.success
  result[keyPath: casePath] = "Goodnight, moon."
}
