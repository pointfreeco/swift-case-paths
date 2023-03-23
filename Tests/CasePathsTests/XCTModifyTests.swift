#if DEBUG && (os(iOS) || os(macOS) || os(tvOS) || os(watchOS))
  @_spi(Internals) import CasePaths
  import XCTest

  final class XCTModifyTests: XCTestCase {
    func testXCTModiftyFailure() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTExpectFailure {
        $0.compactDescription == """
          XCTModify failed: expected to extract value of type "Int" from "Result<Int, Error>"
          """
      }

      var result = Result<Int, Error>.failure(SomeError())
      XCTModify(&result, case: /Result.success) {
        $0 += 1
      }
    }

    func testXCTModiftyFailure_OptionalPromotion() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTExpectFailure {
        $0.compactDescription == """
          XCTModify failed: expected to extract value of type "Int" from \
          "Optional<Result<Int, Error>>"
          """
      }

      var result = Optional(Result<Int, Error>.failure(SomeError()))
      XCTModify(&result, case: /Result.success) {
        $0 += 1
      }
    }

    func testXCTModiftyFailure_Nil_OptionalPromotion() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTExpectFailure {
        $0.compactDescription == """
          XCTModify failed: expected to extract value of type "Int" from \
          "Optional<Result<Int, Error>>"
          """
      }

      var result = Optional<Result<Int, Error>>.none
      XCTModify(&result, case: /Result.success) {
        $0 += 1
      }
    }

    func testXCTModifyFailure_WithMessage() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTExpectFailure {
        $0.compactDescription == """
          XCTModify failed: expected to extract value of type "Int" from "Result<Int, Error>" - \
          Should be success
          """
      }

      var result = Result<Int, Error>.failure(SomeError())
      XCTModify(&result, case: /Result.success, "Should be success") {
        $0 += 1
      }
    }

    func testXCTModifyPass() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      var result = Result<Int, SomeError>.success(2)
      XCTModify(&result, case: /Result.success) {
        $0 += 1
      }
      XCTAssertEqual(result, .success(3))
    }

    func testXCTModifyPass_OptionalPromotion() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      var result = Optional(Result<Int, SomeError>.success(2))
      XCTModify(&result, case: /Result.success) {
        $0 += 1
      }
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
      XCTModify(&result, case: /Result.success) {
        _ = $0
      }
      XCTAssertEqual(result, .success(2))
    }

    func testXCTModify_BodyThrowsError() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      XCTExpectFailure {
        $0.compactDescription == """
          Threw error: SomeError()
          """
      }

      var result = Result<Int, SomeError>.success(2)
      XCTModify(&result, case: /Result.success) { _ in
        throw SomeError()
      }
      XCTAssertEqual(result, .success(2))
    }

    func testXCTModifyFailUnchangedEquatable_NonExhaustive() throws {
      try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil)

      var result = Result<Int, SomeError>.success(2)
      XCTModifyLocals.$isExhaustive.withValue(false) {
        XCTModify(&result, case: /Result.success) {
          _ = $0
        }
      }
      XCTAssertEqual(result, .success(2))
    }
  }

  private struct SomeError: Error, Equatable {}
#endif
