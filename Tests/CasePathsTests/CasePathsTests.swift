import CasePaths
import XCTest

final class CasePathsTests: XCTestCase {
  func testEmbed() {
    enum Foo: Equatable { case bar(Int) }

    let fooBar = /Foo.bar
    XCTAssertEqual(.bar(42), fooBar.embed(42))
    XCTAssertEqual(.bar(42), (/Foo.self).embed(Foo.bar(42)))
  }

  func testNestedEmbed() {
    enum Foo: Equatable { case bar(Bar) }
    enum Bar: Equatable { case baz(Int) }

    let fooBaz = /Foo.bar .. Bar.baz
    XCTAssertEqual(.bar(.baz(42)), fooBaz.embed(42))
  }

  func testVoidCasePath() {
    enum Foo: Equatable { case bar }

//    let fooBar = /Foo.bar
    XCTAssertEqual(.bar, (/Foo.bar).embed(()))
  }

  func testCasePaths() {
    let some = /String?.some
    XCTAssertEqual(
      .some("Hello"),
      some.extract(from: "Hello")
    )
    XCTAssertNil(
      some.extract(from: .none)
    )

    let success = /Result<String, Error>.success
    let failure = /Result<String, Error>.failure
    XCTAssertEqual(
      .some("Hello"),
      success.extract(from: .success("Hello"))
    )
    XCTAssertNil(
      failure.extract(from: .success("Hello"))
    )

    struct MyError: Equatable, Error {}
    let mySuccess = /Result<String, MyError>.success
    let myFailure = /Result<String, MyError>.failure
    XCTAssertEqual(
      .some(MyError()),
      myFailure.extract(from: .failure(MyError()))
    )
    XCTAssertNil(
      mySuccess.extract(from: .failure(MyError()))
    )
  }

  func testIdentity() {
    let id = /Int.self
    XCTAssertEqual(
      .some(42),
      id.extract(from: 42)
    )

    XCTAssertEqual(
      .some(42),
      (/.self).extract(from: 42)
    )

    XCTAssertEqual(
      .some(42),
      (/{ $0 }).extract(from: 42)
    )
  }

  func testLabeledCases() {
    enum Foo: Equatable {
      case bar(some: Int)
      case bar(none: Int)
    }

    let fooBarSome = /Foo.bar(some:)
    let fooBarNone = /Foo.bar(none:)
    XCTAssertEqual(
      .some(42),
      fooBarSome.extract(from: .bar(some: 42))
    )
    XCTAssertNil(
      fooBarSome.extract(from: .bar(none: 42))
    )

    XCTAssertEqual(
      .some(42),
      fooBarNone.extract(from: .bar(none: 42))
    )
    XCTAssertNil(
      fooBarNone.extract(from: .bar(some: 42))
    )
  }

  func testMultiCases() {
    enum Foo {
      case bar(Int, String)
    }

    let fooBar = /Foo.bar
    guard let fizzBuzz = fooBar.extract(from: .bar(42, "Blob"))
    else {
      XCTFail()
      return
    }
    XCTAssertEqual(42, fizzBuzz.0)
    XCTAssertEqual("Blob", fizzBuzz.1)
  }

  func testMultiLabeledCases() {
    enum Foo {
      case bar(fizz: Int, buzz: String)
    }

    let fooBar: CasePath<Foo, (fizz: Int, buzz: String)> = /Foo.bar(fizz:buzz:)
    guard let fizzBuzz = fooBar.extract(from: .bar(fizz: 42, buzz: "Blob"))
    else {
      XCTFail()
      return
    }
    XCTAssertEqual(42, fizzBuzz.fizz)
    XCTAssertEqual("Blob", fizzBuzz.buzz)
  }

  func testSingleValueExtractionFromMultiple() {
    enum Foo {
      case bar(fizz: Int, buzz: String)
    }

    XCTAssertEqual(
      .some(42),
      extract(case: { Foo.bar(fizz: $0, buzz: "Blob") }, from: .bar(fizz: 42, buzz: "Blob"))
    )
  }

  func testMultiMixedCases() {
    enum Foo {
      case bar(Int, buzz: String)
    }

    let fooBar = /Foo.bar
    guard let fizzBuzz = fooBar.extract(from: .bar(42, buzz: "Blob"))
    else {
      XCTFail()
      return
    }
    XCTAssertEqual(42, fizzBuzz.0)
    XCTAssertEqual("Blob", fizzBuzz.1)
  }

  func testNestedReflection() {
    enum Foo {
      case bar(Bar)
    }
    enum Bar {
      case baz(Int)
    }

    XCTAssertEqual(
      42,
      extract(case: { Foo.bar(.baz($0)) }, from: .bar(.baz(42)))
    )
  }

  func testNestedZeroMemoryLayout() {
    enum Foo {
      case bar(Bar)
    }
    enum Bar: Equatable {
      case baz
    }

    let fooBar = /Foo.bar
    XCTAssertEqual(
      .baz,
      fooBar.extract(from: .bar(.baz))
    )
  }

  func testNestedUninhabitedTypes() {
    enum Uninhabited {}

    enum Foo {
      case foo
      case bar(Uninhabited)
      case baz(Never)
    }

    let fooBar = /Foo.bar
    XCTAssertNil(fooBar.extract(from: Foo.foo))

    let fooBaz = /Foo.baz
    XCTAssertNil(fooBaz.extract(from: Foo.foo))
  }

  func testEnumsWithoutAssociatedValues() {
    enum Foo: Equatable {
      case bar
      case baz
    }

    XCTAssertNotNil(
      (/Foo.bar)
        .extract(from: .bar)
    )
    XCTAssertNil(
      (/Foo.bar)
        .extract(from: .baz)
    )

    XCTAssertNotNil(
      (/Foo.baz)
        .extract(from: .baz)
    )
    XCTAssertNil(
      (/Foo.baz)
        .extract(from: .bar)
    )

    XCTAssertNotNil(
      extract(case: { Foo.bar }, from: .bar)
    )
    XCTAssertNil(
      extract(case: { Foo.bar }, from: .baz)
    )

    XCTAssertNotNil(
      extract(case: { Foo.baz }, from: .baz)
    )
    XCTAssertNil(
      extract(case: { Foo.baz }, from: .bar)
    )
  }

  func testEnumsWithClosures() {
    enum Foo {
      case bar(() -> Void)
    }

    var didRun = false
    let fooBar = /Foo.bar
    guard let bar = fooBar.extract(from: .bar { didRun = true })
    else {
      XCTFail()
      return
    }
    bar()
    XCTAssertTrue(didRun)
  }

  func testRecursive() {
    indirect enum Foo {
      case foo(Foo)
      case bar(Int)
    }

    XCTAssertEqual(
      .some(42),
      extract(case: { Foo.foo(.foo(.foo(.bar($0)))) }, from: .foo(.foo(.foo(.bar(42)))))
    )
    XCTAssertNil(
      extract(case: { Foo.foo(.foo(.foo(.bar($0)))) }, from: .foo(.foo(.bar(42))))
    )
  }

  func testExtract() {
    struct MyError: Error {}

    XCTAssertEqual(
      [1],
      [Result.success(1), .success(nil), .failure(MyError())]
        .compactMap(/Result.success .. Optional.some)
    )

    XCTAssertEqual(
      [1],
      [Result.success(1), .success(nil), .failure(MyError())]
        .compactMap(/{ .success(.some($0)) })
    )

    enum Authentication {
      case authenticated(token: String)
      case unauthenticated
    }

    XCTAssertEqual(
      ["deadbeef"],
      [Authentication.authenticated(token: "deadbeef"), .unauthenticated]
        .compactMap(/Authentication.authenticated)
    )

    XCTAssertEqual(
      1,
      [Authentication.authenticated(token: "deadbeef"), .unauthenticated]
        .compactMap(/Authentication.unauthenticated)
        .count
    )
  }

  func testAppending() {
    let success = /Result<Int?, Error>.success
    let int = /Int?.some
    let success2int = success .. int
    XCTAssertEqual(
      .some(42),
      success2int.extract(from: .success(.some(42)))
    )
  }

  func testExample() {
    XCTAssertEqual("Blob", extract(case: Result<String, Error>.success, from: .success("Blob")))
    XCTAssertNil(extract(case: Result<String, Error>.failure, from: .success("Blob")))

    XCTAssertEqual(42, (/Int??.some .. Int?.some).extract(from: Optional(Optional(42))))
  }

  func testConstantCasePath() {
    XCTAssertEqual(.some(42), CasePath.constant(42).extract(from: ()))
    XCTAssertNotNil(CasePath.constant(42).embed(42))
  }

  func testNeverCasePath() {
    XCTAssertNil(CasePath.never.extract(from: 42))
  }

  func testRawValuePath() {
    enum Foo: String { case bar, baz }

    XCTAssertEqual(.some(.bar), CasePath<String, Foo>.rawValue.extract(from: "bar"))
    XCTAssertEqual("baz", CasePath.rawValue.embed(Foo.baz))
  }

  func testDescriptionPath() {
    XCTAssertEqual(.some(42), CasePath.description.extract(from: "42"))
    XCTAssertEqual("42", CasePath.description.embed(42))
  }

  func testA() {
    enum EnumWithLabeledCase {
      case labeled(label: Int, otherLabel: Int)
      case labeled(Int, Int)
    }
    XCTAssertNil((/EnumWithLabeledCase.labeled(label:otherLabel:)).extract(from: .labeled(2, 2)))
    XCTAssertNotNil(
      (/EnumWithLabeledCase.labeled(label:otherLabel:)).extract(
        from: .labeled(label: 2, otherLabel: 2)))
  }

  func testPatternMatching() {
    let results = [
      Result<Int, NSError>.success(1),
      .success(2),
      .failure(NSError(domain: "co.pointfree", code: -1)),
      .success(3),
    ]
    XCTAssertEqual(
      Array(results.lazy.prefix(while: { /Result.success ~= $0 }).compactMap(/Result.success)),
      [1, 2]
    )

    switch results[0] {
    case /Result.success:
      break
    default:
      XCTFail()
    }
  }

  //  func testStructs() {
  //    struct Point { var x: Double, y: Double }
  //
  //    guard
  //      let (x, y) = CasePath(Point.init(x:y:))
  //        .extract(from: Point(x: 16, y: 8))
  //      else {
  //        XCTFail()
  //        return
  //    }
  //
  //    XCTAssertEqual(16, x)
  //    XCTAssertEqual(8, y)
  //
  //    guard
  //      let (x1, y2) = CasePath(Point.init(what:where:))
  //        .extract(from: Point(x: 16, y: 8))
  //      else {
  //        XCTFail()
  //        return
  //    }
  //  }
}
