#if DEBUG
  import CasePaths
  import XCTest

  final class XCTUnwrapTests: XCTestCase {
    func testXCTUnwrapFailure() throws {
      XCTExpectFailure {
        $0.compactDescription == """
          XCTUnwrap failed: expected non-nil value of type "Error"
          """
      }
      _ = try XCTUnwrap(Result<Int, Error>.success(2), case: /Result.failure)
    }

    func testXCTUnwrapFailure_WithMessage() throws {
      XCTExpectFailure {
        $0.compactDescription == """
          XCTUnwrap failed: expected non-nil value of type "Error" - Should be success
          """
      }
      _ = try XCTUnwrap(Result<Int, Error>.success(2), case: /Result.failure, "Should be success")
    }

    func testXCTUnwrapPass() throws {
      XCTAssertEqual(
        try XCTUnwrap(Result<Int, Error>.success(2), case: /Result.success),
        2
      )
    }
  }
#endif
