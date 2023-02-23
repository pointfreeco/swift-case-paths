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
      struct SomeError: Error {}
      try XCTModify(Result<Int, Error>.failure(SomeError()), case: /Result.success) {
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
      struct SomeError: Error {}
      try XCTModify(Optional(Result<Int, Error>.failure(SomeError())), case: /Result.success) {
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
      struct SomeError: Error {}
      try XCTModify(Optional<Result<Int, Error>>.none, case: /Result.success) {
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

      struct SomeError: Error {}
      try XCTModify(
        Result<Int, Error>.failure(SomeError()), case: /Result.success, "Should be success"
      ) {
        $0 += 1
      }
    }

    func testXCTModifyPass() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTAssertEqual(
        try XCTModify(Result<Int, Error>.success(2), case: /Result.success) {
          $0 += 1
          return $0
        },
        3
      )
    }

    func testXCTModifyPass_OptionalPromotion() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTAssertEqual(
        try XCTModify(Optional(Result<Int, Error>.success(2)), case: /Result.success) {
          $0 += 1
          return $0
        },
        3
      )
    }

    func testXCTModifyFailUnchangedEquatable() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTExpectFailure {
        $0.compactDescription == """
          XCTModify failed: expected "Int" value to be modified but it was unchanged.
          """
      }

      XCTAssertEqual(
        try XCTModify(Result<Int, Error>.success(2), case: /Result.success) {
          $0
        },
        2
      )
    }
  }
#endif
