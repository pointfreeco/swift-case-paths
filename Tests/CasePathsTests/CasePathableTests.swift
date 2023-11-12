import CasePaths
import XCTest

final class CasePathableTests: XCTestCase {
  func testModify() {
    struct MyError: Equatable, Error {}
    var result = Result<Int, MyError>.success(1)
    result.modify(\.success) { $0 += 1 }
    XCTAssertEqual(result, .success(2))
  }

  #if DEBUG && !os(Linux) && !os(Windows)
    func testModifyWrongCase() {
      guard ProcessInfo.processInfo.environment["CI"] == nil else { return }
      var response = Result<Int, MyError>.failure(MyError())
      XCTExpectFailure {
        response.modify(\.success) { $0 += 1 }
      }
      XCTAssertEqual(response, .failure(MyError()))
    }
  #endif

  struct MyError: Equatable, Error {}
}
