import CasePaths
import XCTest

final class CasePathableTests: XCTestCase {
  func testModify() {
    struct MyError: Equatable, Error {}
    var result = Result<Int, MyError>.success(1)
    result.modify(\.success) { $0 += 1 }
    XCTAssertEqual(result, .success(2))
  }

  func testModifyWrongCase() {
    struct MyError: Equatable, Error {}
    var response = Result<Int, MyError>.failure(MyError())
    XCTExpectFailure {
      response.modify(\.success) { $0 += 1 }
    } issueMatcher: {
      $0.compactDescription == #"""
        Can't modify 'failure' via 'CaseKeyPath<Response, Int>' \#
        (aka '\Case<Response>.subscript(dynamicMember: <unknown>)')
        """#
    }
    XCTAssertEqual(response, .failure(MyError()))
  }
}
