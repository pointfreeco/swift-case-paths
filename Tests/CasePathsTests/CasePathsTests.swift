import CasePaths
import XCTest

final class CasePathsTests: XCTestCase {
  func testOptional() {
    XCTAssertEqual(Int?.some(42)[case: \.some], 42)
    XCTAssertNil(Int?.none[case: \.some])
    XCTAssertNil(Int?.some(42)[case: \.none])
    XCTAssertNotNil(Int?.none[case: \.none])
    XCTAssertEqual((\Int?.Cases.some)(42), 42)
    XCTAssertEqual((\Int?.Cases.none)(), nil)
    XCTAssertEqual(Fizz.buzz(.fizzBuzz(.int(42)))[case: \.buzz.some.fizzBuzz.some.int], 42)
    let buzzPath1: CaseKeyPath<Fizz, Fizz.AllCasePaths._$buzz> = \Fizz.Cases.buzz
    let buzzPath2 = \Fizz.Cases.buzz.some
    XCTAssertEqual(buzzPath1, \.buzz)
    XCTAssertEqual(buzzPath2, \.buzz.some)
    let buzzPath3 = \Fizz.Cases.buzz
    XCTAssertEqual(buzzPath1, buzzPath3)
    XCTAssertNotEqual(buzzPath2 as PartialCaseKeyPath<Fizz>, buzzPath3)
    XCTAssertEqual(ifLet(state: \Fizz.buzz, action: \Fizz.Cases.buzz), 42)
    XCTAssertEqual(ifLet(state: \Fizz.buzz, action: \Foo.Cases.bar), nil)
    let fizzBuzzPath1 = \Fizz.Cases.buzz.some.fizzBuzz
    let fizzBuzzPath2 = \Fizz.Cases.buzz.some.fizzBuzz.some.int
    let fizzBuzzPath3 = \Fizz.Cases.buzz.some.fizzBuzz.some.int
    XCTAssertNotEqual(fizzBuzzPath1 as PartialCaseKeyPath<Fizz>, fizzBuzzPath3)
    XCTAssertEqual(fizzBuzzPath2, fizzBuzzPath3)
    XCTAssertEqual(Optional.allCasePaths[Int?.some(42)], \.some)
    XCTAssertNotEqual(Optional.allCasePaths[Int?.some(42)], \.none)
    XCTAssertEqual(Optional.allCasePaths[Int?.none], \.none)
    XCTAssertNotEqual(Optional.allCasePaths[Int?.none], \.some)
  }

  func testResult() {
    struct SomeError: Error, Equatable {}
    XCTAssertEqual(Result<Int, any Error>.success(42)[case: \.success], 42)
    XCTAssertNil(Result<Int, any Error>.failure(SomeError())[case: \.success])
    XCTAssertNil(Result<Int, any Error>.success(42)[case: \.failure])
    XCTAssertNotNil(Result<Int, any Error>.failure(SomeError())[case: \.failure])
    XCTAssertEqual((\Result<Int, SomeError>.Cases.success)(42), .success(42))
    XCTAssertEqual((\Result<Int, SomeError>.Cases.failure)(SomeError()), .failure(SomeError()))
    XCTAssertEqual(Result.allCasePaths[Result<Int, any Error>.success(42)], \.success)
    XCTAssertNotEqual(Result.allCasePaths[Result<Int, any Error>.success(42)], \.failure)
    XCTAssertEqual(Result.allCasePaths[Result<Int, any Error>.failure(SomeError())], \.failure)
    XCTAssertNotEqual(Result.allCasePaths[Result<Int, any Error>.failure(SomeError())], \.success)
  }

  func testSelfCaseKeyPathCallAsFunction() {
    var loadable = Loadable.isLoading(progress: 0)
    loadable = (\.self as CaseKeyPath<Loadable, Loadable.AllCasePaths>)(.isLoading(progress: 0.5))
    XCTAssertEqual(loadable, .isLoading(progress: 0.5))
    loadable = (\.self as CaseKeyPath<Loadable, Loadable.AllCasePaths>)(.isLoaded)
    XCTAssertEqual(loadable, .isLoaded)
  }

  func testCaseKeyPaths() {
    var foo: Foo = .bar(.int(1))

    XCTAssertEqual(foo.case, \.bar)

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

    XCTAssertEqual(Foo.allCasePaths[.bar(.int(1))], \.bar)
    XCTAssertEqual(Foo.allCasePaths[.baz(.string(""))], \.baz)
    XCTAssertEqual(Foo.allCasePaths[.fizzBuzz], \.fizzBuzz)
    XCTAssertEqual(Foo.allCasePaths[.foo(nil)], \.foo)

    XCTAssertEqual(
      Array(Foo.allCasePaths),
      [
        \.bar,
        \.baz,
        \.fizzBuzz,
        \.blob,
        \.foo,
      ]
    )
  }

  func testCasePathableModify() {
    var foo = Foo.bar(.int(21))
    foo.modify(\.bar.int) { $0 *= 2 }
    XCTAssertEqual(foo, .bar(.int(42)))
  }

  #if DEBUG && !os(Linux) && !os(Windows) && !os(WASI) && !os(Android)
    func testCasePathableModify_Failure() {
      guard ProcessInfo.processInfo.environment["CI"] == nil else { return }
      var foo = Foo.bar(.int(21))
      XCTExpectFailure {
        foo.modify(\.baz.string) { $0.append("!") }
      }
      XCTAssertEqual(foo, .bar(.int(21)))
    }
  #endif

  func testManualAnyCasePathConformance() {
    // A hand-written conformance in the documented 1.x style, vending
    // 'AnyCasePath' properties, still supplies working case key paths.
    XCTAssertEqual(Legacy.wrapped(.bar(.int(42)))[case: \.wrapped], .bar(.int(42)))
    XCTAssertEqual(Legacy.wrapped(.bar(.int(42)))[case: \.wrapped.bar.int], 42)
    XCTAssertNil(Legacy.count(1)[case: \.wrapped])
    XCTAssertEqual((\Legacy.Cases.wrapped.bar.int)(1), .wrapped(.bar(.int(1))))
    var legacy = Legacy.count(1)
    legacy.modify(\.count) { $0 += 1 }
    XCTAssertEqual(legacy, .count(2))
  }

  func testDeepPartialIs() {
    XCTAssertTrue(Foo.bar(.int(42)).is(\.bar.int))
    XCTAssertFalse(Foo.baz(.string("")).is(\.bar.int))
    XCTAssertTrue(Foo.bar(.int(42)).is(\.self))
  }

  func testAnyCasePathFromKeyPath() {
    let path = AnyCasePath(\Foo.Cases.bar.int)
    XCTAssertEqual(path.extract(from: .bar(.int(42))), 42)
    XCTAssertNil(path.extract(from: .fizzBuzz))
    XCTAssertEqual(path.embed(1), .bar(.int(1)))
  }

  func testPathHashable() {
    // Value-level path identity: equal iff the same case chain, however composed.
    let spelled = Foo.allCasePaths[keyPath: \.bar.int]
    let appended = Foo.allCasePaths[keyPath: (\Foo.Cases.bar).appending(path: \.int)]
    XCTAssertEqual(spelled, appended)

    // Paths as dictionary keys, across enums, without key path hashing:
    var registry: [AnyHashable: String] = [:]
    registry[AnyHashable(Foo.allCasePaths.bar)] = "bar"
    registry[AnyHashable(Foo.allCasePaths[keyPath: \.bar.int])] = "bar.int"
    registry[AnyHashable(Bar.allCasePaths.int)] = "int"
    XCTAssertEqual(registry[AnyHashable(Foo.allCasePaths[keyPath: \.bar])], "bar")
    XCTAssertEqual(registry[AnyHashable(spelled)], "bar.int")
    XCTAssertEqual(registry.count, 3)
  }

  func testCasePathRecovery() {
    let keyPath = \Foo.Cases.bar.int
    let path = Foo.allCasePaths[keyPath: keyPath]
    XCTAssertEqual(path.extract(from: .bar(.int(42))), 42)
    XCTAssertNil(path.extract(from: .fizzBuzz))
    XCTAssertEqual(path.embed(1), .bar(.int(1)))
    XCTAssertEqual(MemoryLayout.size(ofValue: path), 0)
  }

  func testAppendIdentity() {
    let appended = (\Foo.Cases.bar).appending(path: \.int)
    XCTAssertEqual(appended, \Foo.Cases.bar.int)
    XCTAssertEqual(appended.hashValue, (\Foo.Cases.bar.int).hashValue)
    let set: Set<PartialCaseKeyPath<Foo>> = [\Foo.Cases.bar.int, \Foo.Cases.baz]
    XCTAssertTrue(set.contains(appended))
  }

  func testAppend() {
    let fooToBar = \Foo.Cases.bar
    let barToInt = \Bar.Cases.int
    let fooToInt = fooToBar.appending(path: barToInt)

    XCTAssertEqual(Foo.bar(.int(42))[case: fooToInt], 42)
    XCTAssertEqual(Foo.baz(.string("Hello"))[case: fooToInt], nil)
    XCTAssertEqual(Foo.bar(.int(123)), fooToInt(123))
  }

  func testPartialCaseKeyPath() {
    let partialPath = \Foo.Cases.bar as PartialCaseKeyPath<Foo>
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

  func testIs_Optional() {
    XCTAssertTrue(Optional(Foo.fizzBuzz).is(\.fizzBuzz))
    XCTAssertFalse(Optional(Foo.fizzBuzz).is(\.bar))
    XCTAssertFalse(Optional(Foo.fizzBuzz).is(\.baz))
    XCTAssertFalse(Optional(Foo.fizzBuzz).is(\.blob))
    XCTAssertFalse(Optional(Foo.fizzBuzz).is(\.foo))
  }
}

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

@CasePathable
private enum Loadable: Equatable {
  case isLoading(progress: Float)
  case isLoaded
}

func ifLet<A, B, C, Path, D>(
  state: KeyPath<A, B?>, action: CaseKeyPath<C, Path>
) -> Int? where Path.Value == D? { 42 }
@_disfavoredOverload
func ifLet<A, B, C, Path>(
  state: KeyPath<A, B?>, action: CaseKeyPath<C, Path>
) -> Int? { nil }

private enum Legacy: CasePathable, Equatable {
  case wrapped(Foo)
  case count(Int)

  struct AllCasePaths: CasePath {
    func embed(_ value: Legacy) -> Legacy { value }
    func extract(from root: Legacy) -> Legacy? { root }

    var wrapped: AnyCasePath<Legacy, Foo> {
      AnyCasePath(
        embed: { .wrapped($0) },
        extract: {
          guard case .wrapped(let value) = $0 else { return nil }
          return value
        }
      )
    }

    var count: AnyCasePath<Legacy, Int> {
      AnyCasePath(
        embed: { .count($0) },
        extract: {
          guard case .count(let value) = $0 else { return nil }
          return value
        }
      )
    }
  }

  static var allCasePaths: AllCasePaths { AllCasePaths() }
}
