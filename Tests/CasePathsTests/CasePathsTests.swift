import CasePaths
import XCTest

final class CasePathsTests: XCTestCase {
  func testOptional() {
    XCTAssertEqual(Int?.some(42)[case: \.some], 42)
    XCTAssertNil(Int?.none[case: \.some])
    XCTAssertNil(Int?.some(42)[case: \.none])
    XCTAssertNotNil(Int?.none[case: \.none])
    #if swift(>=5.9)
      XCTAssertEqual((\Int?.Cases.some)(42), 42)
      XCTAssertEqual((\Int?.Cases.none)(), nil)
    #else
      let somePath: CaseKeyPath<Int?, Int> = \.some
      let nonePath: CaseKeyPath<Int?, Void> = \.none
      XCTAssertEqual(somePath(42), 42)
      XCTAssertEqual(nonePath(), nil)
    #endif
    #if swift(>=5.9)
      XCTAssertEqual(Fizz.buzz(.fizzBuzz(.int(42)))[case: \.buzz.fizzBuzz.int], 42)
      let buzzPath1: CaseKeyPath<Fizz, Buzz?> = \Fizz.Cases.buzz
      let buzzPath2: CaseKeyPath<Fizz, Buzz> = \Fizz.Cases.buzz
      XCTAssertEqual(buzzPath1, \.buzz)
      XCTAssertEqual(buzzPath2, \.buzz)
      let buzzPath3 = \Fizz.Cases.buzz
      XCTAssertEqual(buzzPath1, buzzPath3)
      XCTAssertNotEqual(buzzPath2, buzzPath3)
      XCTAssertEqual(ifLet(state: \Fizz.buzz, action: \Fizz.Cases.buzz), 42)
      XCTAssertEqual(ifLet(state: \Fizz.buzz, action: \Foo.Cases.bar), nil)
      let fizzBuzzPath1: CaseKeyPath<Fizz, Int?> = \Fizz.Cases.buzz.fizzBuzz.int
      let fizzBuzzPath2: CaseKeyPath<Fizz, Int> = \Fizz.Cases.buzz.fizzBuzz.int
      let fizzBuzzPath3 = \Fizz.Cases.buzz.fizzBuzz.int
      XCTAssertNotEqual(fizzBuzzPath1, fizzBuzzPath3)
      XCTAssertEqual(fizzBuzzPath2, fizzBuzzPath3)
    #endif
  }

  func testResult() {
    struct SomeError: Error, Equatable {}
    XCTAssertEqual(Result<Int, Error>.success(42)[case: \.success], 42)
    XCTAssertNil(Result<Int, Error>.failure(SomeError())[case: \.success])
    XCTAssertNil(Result<Int, Error>.success(42)[case: \.failure])
    XCTAssertNotNil(Result<Int, Error>.failure(SomeError())[case: \.failure])
    #if swift(>=5.9)
      XCTAssertEqual((\Result<Int, SomeError>.Cases.success)(42), .success(42))
      XCTAssertEqual((\Result<Int, SomeError>.Cases.failure)(SomeError()), .failure(SomeError()))
    #else
      let successPath: CaseKeyPath<Result<Int, SomeError>, Int> = \.success
      let failurePath: CaseKeyPath<Result<Int, SomeError>, SomeError> = \.failure
      XCTAssertEqual(successPath(42), .success(42))
      XCTAssertEqual(failurePath(SomeError()), .failure(SomeError()))
    #endif
  }

  func testSelfCaseKeyPathCallAsFunction() {
    enum Loadable: Equatable {
      case isLoading(progress: Float)
      case isLoaded
    }

    var loadable = Loadable.isLoading(progress: 0)
    loadable = (\.self as CaseKeyPath<Loadable, Loadable>)(.isLoading(progress: 0.5))
    XCTAssertEqual(loadable, .isLoading(progress: 0.5))
    loadable = (\.self as CaseKeyPath<Loadable, Loadable>)(.isLoaded)
    XCTAssertEqual(loadable, .isLoaded)
  }

  #if swift(>=5.9)
    func testCaseKeyPaths() {
      var foo: Foo = .bar(.int(1))

      XCTAssertEqual(foo.bar, .int(1))
      // NB: Due to a Swift bug, this is only possible to do outside the library:
      // XCTAssertEqual(foo.bar?.int, 1)

      XCTAssertEqual(foo[keyPath: \.bar], .int(1))
      XCTAssertEqual(foo[keyPath: \.bar?.int], 1)

      XCTAssertEqual(foo[case: \.bar], .int(1))
      XCTAssertEqual(foo[case: \.bar.int], 1)

      foo[case: \.bar] = .int(42)

      XCTAssertEqual(foo, .bar(.int(42)))

      foo[case: \.baz] = .string("Forty-two")

      XCTAssertEqual(foo, .bar(.int(42)))

      foo[case: \.bar.int] = 1792

      XCTAssertEqual(foo, .bar(.int(1792)))

      foo[case: \.baz.string] = "Seventeen hundred and ninety-two"

      XCTAssertEqual(foo, .bar(.int(1792)))

      foo[case: \.bar] = .int(42)

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

    #if DEBUG && !os(Linux) && !os(Windows)
      func testCasePathableModify_Failure() {
        guard ProcessInfo.processInfo.environment["CI"] == nil else { return }
        var foo = Foo.bar(.int(21))
        XCTExpectFailure {
          foo.modify(\.baz.string) { $0.append("!") }
        }
        XCTAssertEqual(foo, .bar(.int(21)))
      }
    #endif

    func testAppend() {
      let fooToBar = \Foo.Cases.bar
      let barToInt = \Bar.Cases.int
      let fooToInt = fooToBar.appending(path: barToInt)

      XCTAssertEqual(Foo.bar(.int(42))[case: fooToInt], 42)
      XCTAssertEqual(Foo.baz(.string("Hello"))[case: fooToInt], nil)
      XCTAssertEqual(Foo.bar(.int(123)), fooToInt(123))
    }

    func testMatch() {
      switch Foo.bar(.int(42)) {
      case \.bar.int:
        break
      default:
        XCTFail()
      }

      switch Foo.bar(.int(42)) {
      case \.bar:
        break
      default:
        XCTFail()
      }

      XCTAssertTrue(Foo.bar(.int(42)).is(\.bar))
      XCTAssertTrue(Foo.bar(.int(42)).is(\.bar.int))
      XCTAssertFalse(Foo.bar(.int(42)).is(\.baz))
      XCTAssertFalse(Foo.bar(.int(42)).is(\.baz.string))
      XCTAssertFalse(Foo.bar(.int(42)).is(\.blob))
      XCTAssertFalse(Foo.bar(.int(42)).is(\.fizzBuzz))
      XCTAssertTrue(Foo.foo(nil).is(\.foo))
      XCTAssertTrue(Foo.foo(nil).is(\.foo.none))
      XCTAssertTrue(Foo.foo("").is(\.foo))
      XCTAssertFalse(Foo.foo(nil).is(\.bar))
    }

    func testPartialCaseKeyPath() {
      let partialPath = \Foo.Cases.bar as PartialCaseKeyPath
      XCTAssertEqual(.bar(.int(42)), partialPath(Bar.int(42)))
      XCTAssertNil(partialPath(42))

      XCTAssertEqual(.int(42), Foo.bar(.int(42))[case: partialPath] as? Bar)
      XCTAssertNil(Foo.baz(.string("Hello"))[case: partialPath])
    }

    func testExistentials() {
      let caseA: PartialCaseKeyPath<A> = \.a
      let caseB: PartialCaseKeyPath<B> = \.b

      let a = A.a("Hello")
      guard let valueA = a[case: caseA] else { return XCTFail() }
      guard let b = caseB(valueA) else { return XCTFail() }
      XCTAssertEqual(b, .b("Hello"))
    }

    func testExistentials_Optional() {
      let foo: PartialCaseKeyPath<Foo> = \.foo
      XCTAssertNotNil(foo(String?.none as Any))
      XCTAssertNotNil(foo(String?.some("Blob") as Any))
      XCTAssertNotNil(foo("Blob"))
    }
  #endif
}

#if swift(>=5.9)
  @CasePathable
  enum A: Equatable {
    case a(String)
  }

  @CasePathable
  enum B: Equatable {
    case b(String)
  }

  @CasePathable @dynamicMemberLookup enum Foo: Equatable {
    case bar(Bar)
    case baz(Baz)
    case fizzBuzz
    case blob(Blob)
    case foo(String?)
  }
  @CasePathable @dynamicMemberLookup enum Bar: Equatable {
    case int(Int)
  }
  @CasePathable @dynamicMemberLookup enum Baz: Equatable {
    case string(String)
  }
  @CasePathable enum Blob: Equatable {
  }
  @CasePathable @dynamicMemberLookup enum Fizz: Equatable {
    case buzz(Buzz?)
  }
  @CasePathable @dynamicMemberLookup enum Buzz: Equatable {
    case fizzBuzz(FizzBuzz?)
  }
  @CasePathable @dynamicMemberLookup enum FizzBuzz: Equatable {
    case int(Int)
  }

  func ifLet<A, B, C, D>(state: KeyPath<A, B?>, action: CaseKeyPath<C, D?>) -> Int? { 42 }
  @_disfavoredOverload
  func ifLet<A, B, C, D>(state: KeyPath<A, B?>, action: CaseKeyPath<C, D>) -> Int? { nil }
#endif
