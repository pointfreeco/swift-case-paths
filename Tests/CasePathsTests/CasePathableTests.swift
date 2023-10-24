import CasePaths
import XCTest

final class CasePathableTests: XCTestCase {
  func testModify() {
    struct MyError: Equatable, Error {}
    var result = Result<Int, MyError>.success(1)
    result.modify(\.success) { $0 += 1 }
    XCTAssertEqual(result, .success(2))
  }

  #if !os(Linux) && !os(Windows)
    func testModifyWrongCase() {
      var response = Result<Int, MyError>.failure(MyError())
      XCTExpectFailure {
        response.modify(\.success) { $0 += 1 }
      } issueMatcher: {
        $0.compactDescription == #"""
          Can't modify 'failure(CasePathsTests.CasePathableTests.MyError())' \#
          via 'CaseKeyPath<Result<Int, MyError>, Int>' \#
          (aka '\Case<Result<Int, MyError>>.subscript(dynamicMember: <unknown>)')
          """#
      }
      XCTAssertEqual(response, .failure(MyError()))
    }
  #endif

  struct MyError: Equatable, Error {}
}

