#if DEBUG && (os(iOS) || os(macOS) || os(tvOS) || os(watchOS))
  import CasePaths
  import XCTest

  final class XCTUnwrapTests: XCTestCase {
    func testXCTUnwrapFailure() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTExpectFailure {
        $0.compactDescription == """
          XCTUnwrap failed: expected non-nil value of type "Error"
          """
      }
      _ = try XCTUnwrap(Result<Int, Error>.success(2), case: /Result.failure)
    }

    func testXCTUnwrapFailure_WithMessage() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTExpectFailure {
        $0.compactDescription == """
          XCTUnwrap failed: expected non-nil value of type "Error" - Should be success
          """
      }
      _ = try XCTUnwrap(Result<Int, Error>.success(2), case: /Result.failure, "Should be success")
    }

    func testXCTUnwrapPass() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTAssertEqual(
        try XCTUnwrap(Result<Int, Error>.success(2), case: /Result.success),
        2
      )
    }
  }
#endif
