import CasePaths
import Foundation
import Testing

struct CasePathsTests {
  @Test func optional() {
    #expect(Int?.some(42)[case: \.some] == 42)
    #expect(Int?.none[case: \.some] == nil)
    #expect(Int?.some(42)[case: \.none] == nil)
    #expect(Int?.none[case: \.none] != nil)
    #expect((\Int?.Cases.some)(42) == 42)
    #expect((\Int?.Cases.none)() == nil)
    #expect(Fizz.buzz(.fizzBuzz(.int(42)))[case: \.buzz.some.fizzBuzz.some.int] == 42)
    let buzzPath1: CaseKeyPath<Fizz, Fizz.AllCasePaths._$buzz> = \Fizz.Cases.buzz
    let buzzPath2 = \Fizz.Cases.buzz.some
    #expect(buzzPath1 == \.buzz)
    #expect(buzzPath2 == \.buzz.some)
    let buzzPath3 = \Fizz.Cases.buzz
    #expect(buzzPath1 == buzzPath3)
    #expect(buzzPath2 as PartialCaseKeyPath<Fizz> != buzzPath3)
    #expect(ifLet(state: \Fizz.buzz, action: \Fizz.Cases.buzz) == 42)
    #expect(ifLet(state: \Fizz.buzz, action: \Foo.Cases.bar) == nil)
    let fizzBuzzPath1 = \Fizz.Cases.buzz.some.fizzBuzz
    let fizzBuzzPath2 = \Fizz.Cases.buzz.some.fizzBuzz.some.int
    let fizzBuzzPath3 = \Fizz.Cases.buzz.some.fizzBuzz.some.int
    #expect(fizzBuzzPath1 as PartialCaseKeyPath<Fizz> != fizzBuzzPath3)
    #expect(fizzBuzzPath2 == fizzBuzzPath3)
    #expect(Optional.allCasePaths[Int?.some(42)] == \.some)
    #expect(Optional.allCasePaths[Int?.some(42)] != \.none)
    #expect(Optional.allCasePaths[Int?.none] == \.none)
    #expect(Optional.allCasePaths[Int?.none] != \.some)
  }

  @Test func result() {
    struct SomeError: Error, Equatable {}
    #expect(Result<Int, any Error>.success(42)[case: \.success] == 42)
    #expect(Result<Int, any Error>.failure(SomeError())[case: \.success] == nil)
    #expect(Result<Int, any Error>.success(42)[case: \.failure] == nil)
    #expect(Result<Int, any Error>.failure(SomeError())[case: \.failure] != nil)
    #expect((\Result<Int, SomeError>.Cases.success)(42) == .success(42))
    #expect((\Result<Int, SomeError>.Cases.failure)(SomeError()) == .failure(SomeError()))
    #expect(Result.allCasePaths[Result<Int, any Error>.success(42)] == \.success)
    #expect(Result.allCasePaths[Result<Int, any Error>.success(42)] != \.failure)
    #expect(Result.allCasePaths[Result<Int, any Error>.failure(SomeError())] == \.failure)
    #expect(Result.allCasePaths[Result<Int, any Error>.failure(SomeError())] != \.success)
  }

  @Test func callAsFunction() {
    var loadable = Loadable.isLoading(progress: 0)
    loadable = (\.self as CaseKeyPath<Loadable, Loadable.AllCasePaths>)(.isLoading(progress: 0.5))
    #expect(loadable == .isLoading(progress: 0.5))
    loadable = (\.self as CaseKeyPath<Loadable, Loadable.AllCasePaths>)(.isLoaded)
    #expect(loadable == .isLoaded)
  }

  @Test func `case key paths`() {
    var foo: Foo = .bar(.int(1))

    #expect(foo.case == \.bar)

    #expect(foo.bar == .int(1))
    #expect(foo.bar?.int == 1)

    #expect(foo[keyPath: \.bar] == .int(1))
    #expect(foo[keyPath: \.bar?.int] == 1)

    #expect(foo[case: \.bar] == .int(1))
    #expect(foo[case: \.bar.int] == 1)

    foo[case: \.bar] = .int(42)

    #expect(foo == .bar(.int(42)))

    foo[case: \.baz] = .string("Forty-two")

    #expect(foo == .bar(.int(42)))

    foo[case: \.bar.int] = 1792

    #expect(foo == .bar(.int(1792)))

    foo[case: \.baz.string] = "Seventeen hundred and ninety-two"

    #expect(foo == .bar(.int(1792)))

    foo[case: \.bar] = .int(42)

    #expect((\Foo.Cases.self)(.bar(.int(1))) == .bar(.int(1)))
    #expect((\Foo.Cases.bar)(.int(1)) == .bar(.int(1)))
    #expect((\Foo.Cases.bar.int)(1) == .bar(.int(1)))
    #expect((\Foo.Cases.fizzBuzz)() == .fizzBuzz)

    #expect(Foo.allCasePaths[.bar(.int(1))] == \.bar)
    #expect(Foo.allCasePaths[.baz(.string(""))] == \.baz)
    #expect(Foo.allCasePaths[.fizzBuzz] == \.fizzBuzz)
    #expect(Foo.allCasePaths[.foo(nil)] == \.foo)

    #expect(
      Array(Foo.allCasePaths) == [
        \.bar,
        \.baz,
        \.fizzBuzz,
        \.blob,
        \.foo,
      ]
    )
  }

  @Test func modify() {
    var foo = Foo.bar(.int(21))
    foo.modify(\.bar.int) { $0 *= 2 }
    #expect(foo == .bar(.int(42)))
  }

  #if DEBUG && !os(Linux) && !os(Windows) && !os(WASI) && !os(Android)
    @Test func `modify failure`() {
      guard ProcessInfo.processInfo.environment["CI"] == nil else { return }
      var foo = Foo.bar(.int(21))
      withKnownIssue {
        foo.modify(\.baz.string) { $0.append("!") }
      }
      #expect(foo == .bar(.int(21)))
    }
  #endif

  @Test func `manual conformance via 'AnyCasePath'`() {
    // A hand-written conformance in the documented 1.x style, vending
    // 'AnyCasePath' properties, still supplies working case key paths.
    #expect(Legacy.wrapped(.bar(.int(42)))[case: \.wrapped] == .bar(.int(42)))
    #expect(Legacy.wrapped(.bar(.int(42)))[case: \.wrapped.bar.int] == 42)
    #expect(Legacy.count(1)[case: \.wrapped] == nil)
    #expect((\Legacy.Cases.wrapped.bar.int)(1) == .wrapped(.bar(.int(1))))
    var legacy = Legacy.count(1)
    legacy.modify(\.count) { $0 += 1 }
    #expect(legacy == .count(2))
  }

  @Test func `deep partial 'is'`() {
    #expect(Foo.bar(.int(42)).is(\.bar.int))
    #expect(!Foo.baz(.string("")).is(\.bar.int))
    #expect(Foo.bar(.int(42)).is(\.self))
  }

  @Test func `'AnyCasePath' from key path`() {
    let path = AnyCasePath<Foo, Int>(\.bar.int)
    #expect(path.extract(from: .bar(.int(42))) == 42)
    #expect(path.extract(from: .fizzBuzz) == nil)
    #expect(path.embed(1) == .bar(.int(1)))
  }

  @Test func `hashable identity`() {
    // Value-level path identity: equal iff the same case chain, however composed.
    let spelled = Foo.allCasePaths[keyPath: \.bar.int]
    let appended = Foo.allCasePaths[keyPath: (\Foo.Cases.bar).appending(path: \.int)]
    #expect(spelled == appended)

    // Paths as dictionary keys, across enums, without key path hashing:
    var registry: [AnyHashable: String] = [:]
    registry[AnyHashable(Foo.allCasePaths.bar)] = "bar"
    registry[AnyHashable(Foo.allCasePaths[keyPath: \.bar.int])] = "bar.int"
    registry[AnyHashable(Bar.allCasePaths.int)] = "int"
    #expect(registry[AnyHashable(Foo.allCasePaths[keyPath: \.bar])] == "bar")
    #expect(registry[AnyHashable(spelled)] == "bar.int")
    #expect(registry.count == 3)
  }

  @Test func recovery() {
    let keyPath = \Foo.Cases.bar.int
    let path = Foo.allCasePaths[keyPath: keyPath]
    #expect(path.extract(from: .bar(.int(42))) == 42)
    #expect(path.extract(from: .fizzBuzz) == nil)
    #expect(path.embed(1) == .bar(.int(1)))
    #expect(MemoryLayout.size(ofValue: path) == 0)
  }

  @Test func `append identity`() {
    let appended = (\Foo.Cases.bar).appending(path: \.int)
    #expect(appended == \Foo.Cases.bar.int)
    #expect(appended.hashValue == (\Foo.Cases.bar.int).hashValue)
    let set: Set<PartialCaseKeyPath<Foo>> = [\Foo.Cases.bar.int, \Foo.Cases.baz]
    #expect(set.contains(appended))
  }

  @Test func append() {
    let fooToBar = \Foo.Cases.bar
    let barToInt = \Bar.Cases.int
    let fooToInt = fooToBar.appending(path: barToInt)

    #expect(Foo.bar(.int(42))[case: fooToInt] == 42)
    #expect(Foo.baz(.string("Hello"))[case: fooToInt] == nil)
    #expect(Foo.bar(.int(123)) == fooToInt(123))
  }

  @Test func `partial paths`() {
    let partialPath = \Foo.Cases.bar as PartialCaseKeyPath<Foo>
    #expect(.bar(.int(42)) == partialPath(Bar.int(42)))
    #expect(partialPath(42) == nil)

    #expect(.int(42) == Foo.bar(.int(42))[case: partialPath] as? Bar)
    #expect(Foo.baz(.string("Hello"))[case: partialPath] == nil)
  }

  @Test func existentials() {
    let caseA: PartialCaseKeyPath<A> = \.a
    let caseB: PartialCaseKeyPath<B> = \.b

    let a = A.a("Hello")
    guard let valueA = a[case: caseA] else {
      Issue.record()
      return
    }
    guard let b = caseB(valueA) else {
      Issue.record()
      return
    }
    #expect(b == .b("Hello"))
  }

  @Test func `existential optionals`() {
    let foo: PartialCaseKeyPath<Foo> = \.foo
    #expect(foo(String?.none as Any) != nil)
    #expect(foo(String?.some("Blob") as Any) != nil)
    #expect(foo("Blob") != nil)
  }

  @Test func `typed and partial 'is'`() {
    let typed = \Foo.Cases.bar.int
    let partial = typed as PartialCaseKeyPath<Foo>
    #expect(Foo.bar(.int(42)).is(typed))
    #expect(Foo.bar(.int(42)).is(partial))
    #expect(!Foo.fizzBuzz.is(typed))
    #expect(!Foo.fizzBuzz.is(partial))
    #expect(Optional(Foo.bar(.int(42))).is(typed))
    #expect(Optional(Foo.bar(.int(42))).is(partial))
    #expect(!Optional<Foo>.none.is(typed))
    #expect(!Optional<Foo>.none.is(partial))
  }

  @Test func `optional 'is'`() {
    #expect(Optional(Foo.fizzBuzz).is(\.fizzBuzz))
    #expect(!Optional(Foo.fizzBuzz).is(\.bar))
    #expect(!Optional(Foo.fizzBuzz).is(\.baz))
    #expect(!Optional(Foo.fizzBuzz).is(\.blob))
    #expect(!Optional(Foo.fizzBuzz).is(\.foo))
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

  struct AllCasePaths: CasePathReflectable, Sequence {
    func embed(_ value: Legacy) -> Legacy { value }
    func extract(from root: Legacy) -> Legacy? { root }

    subscript(root: Legacy) -> PartialCaseKeyPath<Legacy> {
      switch root {
      case .wrapped: return \.wrapped
      case .count: return \.count
      }
    }

    func makeIterator() -> IndexingIterator<[PartialCaseKeyPath<Legacy>]> {
      [\.wrapped, \.count].makeIterator()
    }

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
