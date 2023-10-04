import CasePaths
import XCTest

final class CasePathsTests: XCTestCase {
  func testCaseKeyPaths() {
    var foo: Foo = .bar(.int(1))

    XCTAssertEqual(foo.bar, .int(1))
    XCTAssertEqual(foo.bar?.int, 1)

    XCTAssertEqual(foo[keyPath: \.bar], .int(1))
    XCTAssertEqual(foo[keyPath: \.bar?.int], 1)

    foo[keyPath: \.bar] = .int(42)

    XCTAssertEqual(foo, .bar(.int(42)))

    foo[keyPath: \.baz] = .string("Forty-two")

    XCTAssertEqual(foo, .bar(.int(42)))

    foo[keyPath: \.bar.int] = 1792

    XCTAssertEqual(foo, .bar(.int(1792)))

    foo[keyPath: \.baz.string] = "Seventeen hundred and ninety-two"

    XCTAssertEqual(foo, .bar(.int(1792)))

    foo[keyPath: \.bar] = .int(42)

    XCTAssertEqual((\Foo.Cases.self)(.bar(.int(1))), .bar(.int(1)))
    XCTAssertEqual((\Foo.Cases.bar)(.int(1)), .bar(.int(1)))
    XCTAssertEqual((\Foo.Cases.bar.int)(1), .bar(.int(1)))
    XCTAssertEqual((\Foo.Cases.fizzBuzz)(), .fizzBuzz)
  }

  func testCasePathableModify() {
    var foo = Foo.bar(.int(21))
    foo.modify(\.bar.int) { $0 *= 2 }
    XCTAssertEqual(foo, .bar(.int(42)))
  }

  func testCasePathableModify_Failure() {
    var foo = Foo.bar(.int(21))
    XCTExpectFailure {
      foo.modify(\.baz.string) { $0.append("!") }
    }
    XCTAssertEqual(foo, .bar(.int(21)))
  }

  func testOptional() {
    XCTAssertEqual(Int?.some(42)[keyPath: \.some], 42)
    XCTAssertNil(Int?.none[keyPath: \.some])
    XCTAssertEqual((\Int?.Cases.some)(42), 42)
    XCTAssertNil(Int?.some(42)[keyPath: \.none])
    XCTAssertNotNil(Int?.none[keyPath: \.none])
    XCTAssertEqual((\Int?.Cases.none)(), nil)
  }

  func testResult() {
    struct SomeError: Error, Equatable {}
    XCTAssertEqual(Result<Int, Error>.success(42)[keyPath: \.success], 42)
    XCTAssertNil(Result<Int, Error>.failure(SomeError())[keyPath: \.success])
    XCTAssertEqual((\Result<Int, SomeError>.Cases.success)(42), .success(42))
    XCTAssertNil(Result<Int, Error>.success(42)[keyPath: \.failure])
    XCTAssertNotNil(Result<Int, Error>.failure(SomeError())[keyPath: \.failure])
    XCTAssertEqual((\Result<Int, SomeError>.Cases.failure)(SomeError()), .failure(SomeError()))
  }
}

@CasePathable enum Foo: Equatable {
  case bar(Bar)
  case baz(Baz)
  case fizzBuzz
}
@CasePathable enum Bar: Equatable {
  case int(Int)
}
@CasePathable enum Baz: Equatable {
  case string(String)
}
