import CasePaths
import XCTest

final class CasePathableTests: XCTestCase {
  func testModify() {
    var response = Response.success(1)
    response.modify(\.success) { $0 += 1 }
    XCTAssertEqual(response, .success(2))
  }

  func testModifyWrongCase() {
    var response = Response.failure
    XCTExpectFailure {
      response.modify(\.success) { $0 += 1 }
    } issueMatcher: {
      $0.compactDescription == #"""
        Can't modify 'failure' via 'CaseKeyPath<Response, Int>' \#
        (aka '\Case<Response>.subscript(dynamicMember: <unknown>)')
        """#
    }
    XCTAssertEqual(response, .failure)
  }
}

@CasePathable
private enum Response: Equatable {
  case success(Int)
  case failure
}
