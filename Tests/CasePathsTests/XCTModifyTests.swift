#if DEBUG && (os(iOS) || os(macOS) || os(tvOS) || os(watchOS))
  import CasePaths
  import XCTest

  final class XCTModifyTests: XCTestCase {
    func testXCTModiftyFailure() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTExpectFailure {
        $0.compactDescription == """
          XCTModify failed: expected non-nil value of type "Int"
          """
      }

      var result = Result<Int, Error>.failure(SomeError())
      try XCTModify(&result, case: /Result.success) {
        $0 += 1
      }
    }

    func testXCTModiftyFailure_OptionalPromotion() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTExpectFailure {
        $0.compactDescription == """
          XCTModify failed: expected non-nil value of type "Int"
          """
      }

      var result = Optional(Result<Int, Error>.failure(SomeError()))
      try XCTModify(&result, case: /Result.success) {
        $0 += 1
      }
    }

    func testXCTModiftyFailure_Nil_OptionalPromotion() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTExpectFailure {
        $0.compactDescription == """
          XCTModify failed: expected non-nil value of type "Int"
          """
      }

      var result = Optional<Result<Int, Error>>.none
      try XCTModify(&result, case: /Result.success) {
        $0 += 1
      }
    }

    func testXCTModifyFailure_WithMessage() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTExpectFailure {
        $0.compactDescription == """
          XCTModify failed: expected non-nil value of type "Int" - Should be success
          """
      }

      var result = Result<Int, Error>.failure(SomeError())
      try XCTModify(&result, case: /Result.success, "Should be success") {
        $0 += 1
      }
    }

    func testXCTModifyPass() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      var result = Result<Int, SomeError>.success(2)
      XCTAssertEqual(
        try XCTModify(&result, case: /Result.success) {
          $0 += 1
          return $0
        },
        3
      )
      XCTAssertEqual(result, .success(3))
    }

    func testXCTModifyPass_OptionalPromotion() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      var result = Optional(Result<Int, SomeError>.success(2))
      XCTAssertEqual(
        try XCTModify(&result, case: /Result.success) {
          $0 += 1
          return $0
        },
        3
      )
      XCTAssertEqual(result, .success(3))
    }

    func testXCTModifyFailUnchangedEquatable() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTExpectFailure {
        $0.compactDescription == """
          XCTModify failed: expected "Int" value to be modified but it was unchanged.
          """
      }

      var result = Result<Int, SomeError>.success(2)
      XCTAssertEqual(
        try XCTModify(&result, case: /Result.success) {
          $0
        },
        2
      )
      XCTAssertEqual(result, .success(2))
    }
  }

  private struct SomeError: Error, Equatable {}
#endif
