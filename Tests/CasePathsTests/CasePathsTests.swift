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

  func testSelfCaseKeyPathCallAsFunction() {
    enum Loadable: Equatable { case isLoading(progress: Float), isLoaded }

    var loadable = Loadable.isLoading(progress: 0)
    loadable = (\.self as CaseKeyPath<Loadable, Loadable>)(.isLoading(progress: 0.5))
    XCTAssertEqual(loadable, .isLoading(progress: 0.5))
    loadable = (\.self as CaseKeyPath<Loadable, Loadable>)(.isLoaded)
    XCTAssertEqual(loadable, .isLoaded)
  }

  func testAppend() {
    let fooToBar = \Foo.Cases.bar
    let barToInt = \Bar.Cases.int
    let fooToInt = fooToBar.appending(path: barToInt)

    XCTAssertEqual(Foo.bar(.int(42))[keyPath: fooToInt], 42)
    XCTAssertEqual(Foo.baz(.string("Hello"))[keyPath: fooToInt], nil)
    XCTAssertEqual(Foo.bar(.int(123)), fooToInt(123))
  }

  func testMatch() {
    switch Foo.bar(.int(42)) {
    case \.bar.int:
      return
    default:
      XCTFail()
    }

    switch Foo.bar(.int(42)) {
    case \.bar:
      return
    default:
      XCTFail()
    }

    XCTAssertTrue(Foo.bar(.int(42)).is(\.bar))
    XCTAssertTrue(Foo.bar(.int(42)).is(\.bar.int))
    XCTAssertFalse(Foo.bar(.int(42)).is(\.baz))
    XCTAssertFalse(Foo.bar(.int(42)).is(\.baz.string))
    XCTAssertFalse(Foo.bar(.int(42)).is(\.blob))
    XCTAssertFalse(Foo.bar(.int(42)).is(\.fizzBuzz))
  }

  func testPartialCaseKeyPath() {
    let partialPath = \Foo.Cases.bar as PartialCaseKeyPath
    XCTAssertEqual(.bar(.int(42)), partialPath(Bar.int(42)))
    XCTAssertNil(partialPath(42))

    XCTAssertEqual(.int(42), Foo.bar(.int(42))[keyPath: partialPath] as? Bar)
    XCTAssertNil(Foo.baz(.string("Hello"))[keyPath: partialPath])
  }

  func testCasePathIterable() {
    for path in Foo.allCasePaths {
      switch path {
      case \.bar:
        XCTAssertEqual(path(Bar.int(42)), Foo.bar(.int(42)))
        XCTAssertNil(path(Baz.string("Blob")))
        XCTAssertNil(path(()))
      case \.baz:
        XCTAssertNil(path(Bar.int(42)))
        XCTAssertEqual(path(Baz.string("Blob")), Foo.baz(.string("Blob")))
        XCTAssertNil(path(()))
      case \.fizzBuzz:
        XCTAssertNil(path(Bar.int(42)))
        XCTAssertNil(path(Baz.string("Blob")))
        XCTAssertEqual(path(()), Foo.fizzBuzz)
      case \.blob:
        XCTAssertNil(path(42))
      default:
        XCTFail()
      }
    }
    XCTAssertEqual(Array(Foo.allCasePaths), [\.bar, \.baz, \.blob, \.fizzBuzz])
  }
}

@CasePathable @dynamicMemberLookup enum Foo: Equatable {
  case bar(Bar)
  case baz(Baz)
  case fizzBuzz
  case blob(Blob)
}
@CasePathable @dynamicMemberLookup enum Bar: Equatable {
  case int(Int)
}
@CasePathable @dynamicMemberLookup enum Baz: Equatable {
  case string(String)
}
@CasePathable enum Blob: Equatable {
}
