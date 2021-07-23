import CasePaths
import XCTest

// Replace this with XCTUnwrap when we drop support for Xcode 11.3.
private func unwrap<Wrapped>(_ optional: Wrapped?) throws -> Wrapped {
  guard let wrapped = optional else { throw UnexpectedNil() }
  return wrapped
}
private struct UnexpectedNil: Error {}

protocol TestProtocol {}
extension Int: TestProtocol {}

final class CasePathsTests: XCTestCase {
  func testSimplePayload() {
    enum Enum { case payload(Int) }
    let path = /Enum.payload
    for _ in 1...2 {
      XCTAssertEqual(path.extract(from: .payload(42)), 42)
    }
  }

  func testSimpleLabeledPayload() {
    enum Enum { case payload(label: Int) }
    let path = /Enum.payload(label:)
    for _ in 1...2 {
      XCTAssertEqual(path.extract(from: .payload(label: 42)), 42)
    }
  }

  // This test crashes Xcode 11.7's compiler.
  #if compiler(>=5.3)
    func testSimpleOverloadedPayload() {
      enum Enum {
        case payload(a: Int)
        case payload(b: Int)
      }
      let pathA = /Enum.payload(a:)
      let pathB = /Enum.payload(b:)
      for _ in 1...2 {
        XCTAssertEqual(pathA.extract(from: .payload(a: 42)), 42)
        XCTAssertEqual(pathA.extract(from: .payload(b: 42)), nil)
        XCTAssertEqual(pathB.extract(from: .payload(a: 42)), nil)
        XCTAssertEqual(pathB.extract(from: .payload(b: 42)), 42)
      }
    }
  #endif

  func testMultiPayload() {
    enum Enum { case payload(Int, String) }
    let path: CasePath<Enum, (Int, String)> = /Enum.payload
    for _ in 1...2 {
      XCTAssert(try unwrap(path.extract(from: .payload(42, "Blob"))) == (42, "Blob"))
    }
  }

  func testMultiLabeledPayload() {
    enum Enum { case payload(a: Int, b: String) }
    let path: CasePath<Enum, (Int, String)> = /Enum.payload
    for _ in 1...2 {
      XCTAssert(
        try unwrap(path.extract(from: .payload(a: 42, b: "Blob"))) == (42, "Blob")
      )
      XCTAssert(
        try unwrap(path.extract(from: .payload(a: 42, b: "Blob"))) == (a: 42, b: "Blob")
      )
    }
  }

  func testNoPayload() {
    enum Enum { case a, b }
    let pathA = /Enum.a
    let pathB = /Enum.b
    for _ in 1...2 {
      XCTAssertNotNil(pathA.extract(from: .a))
      XCTAssertNotNil(pathB.extract(from: .b))
      XCTAssertNil(pathA.extract(from: .b))
      XCTAssertNil(pathB.extract(from: .a))
    }
  }

  func testZeroMemoryLayoutPayload() {
    struct Unit1 {}
    enum Unit2 { case unit }
    enum Enum {
      case void(Void)
      case unit1(Unit1)
      case unit2(Unit2)
    }
    let path1 = /Enum.void
    let path2 = /Enum.unit1
    let path3 = /Enum.unit2
    for _ in 1...2 {
      XCTAssertNotNil(path1.extract(from: .void(())))
      XCTAssertNotNil(path2.extract(from: .unit1(.init())))
      XCTAssertNotNil(path3.extract(from: .unit2(.unit)))
      XCTAssertNil(path1.extract(from: .unit1(.init())))
      XCTAssertNil(path1.extract(from: .unit2(.unit)))
      XCTAssertNil(path2.extract(from: .void(())))
      XCTAssertNil(path2.extract(from: .unit2(.unit)))
      XCTAssertNil(path3.extract(from: .void(())))
      XCTAssertNil(path3.extract(from: .unit1(.init())))
    }
  }

  func testUninhabitedPayload() {
    enum Uninhabited {}
    enum Enum {
      case never(Never)
      case uninhabited(Uninhabited)
      case value
    }
    let path1 = /Enum.never
    let path2 = /Enum.uninhabited
    for _ in 1...2 {
      XCTAssertNil(path1.extract(from: .value))
      XCTAssertNil(path2.extract(from: .value))
    }
  }

  func testClosurePayload() throws {
    enum Enum { case closure(() -> Void) }
    let path = /Enum.closure
    for _ in 1...2 {
      var invoked = false
      let closure = try unwrap(path.extract(from: .closure { invoked = true }))
      closure()
      XCTAssertTrue(invoked)
    }
  }

  func testRecursivePayload() {
    indirect enum Enum: Equatable {
      case indirect(Enum)
      case direct
    }
    let shallowPath = /Enum.indirect
    let deepPath = /Enum.indirect
    for _ in 1...2 {
      XCTAssertEqual(shallowPath.extract(from: .indirect(.direct)), .direct)
      XCTAssertEqual(
        deepPath.extract(from: .indirect(.indirect(.direct))), .indirect(.direct)
      )
    }
  }

  func testIndirectSimplePayload() {
    enum Enum: Equatable {
      indirect case indirect(Int)
      case direct(Int)
    }

    let indirectPath = /Enum.indirect
    let directPath = /Enum.direct

    for _ in 1...2 {
      do {
        let actual = indirectPath.extract(from: .indirect(42))
        XCTAssertEqual(actual, 42)
      }
      do {
        let actual = indirectPath.extract(from: .direct(42))
        XCTAssertEqual(actual, nil)
      }
      do {
        let actual = directPath.extract(from: .indirect(42))
        XCTAssertEqual(actual, nil)
      }
      do {
        let actual = directPath.extract(from: .direct(42))
        XCTAssertEqual(actual, 42)
      }
    }
  }

  fileprivate class Object: Equatable {
    static func == (lhs: Object, rhs: Object) -> Bool {
      return lhs === rhs
    }
  }

  func testIndirectCompoundPayload() throws {
    let object = Object()

    enum Enum: Equatable {
      indirect case indirect(Int, Object?, Int, Object?)
      case direct(Int, Object?, Int, Object?)
    }

    let indirectPath: CasePath<Enum, (Int, Object?, Int, Object?)> = /Enum.indirect
    let directPath: CasePath<Enum, (Int, Object?, Int, Object?)> = /Enum.direct

    for _ in 1...2 {
      do {
        let actual = indirectPath.extract(from: .indirect(42, nil, 43, object))
        XCTAssert(try unwrap(actual) == (42, nil, 43, object))
      }
      do {
        let actual = indirectPath.extract(from: .direct(42, nil, 43, object))
        XCTAssertNil(actual)
      }
      do {
        let actual = directPath.extract(from: .indirect(42, nil, 43, object))
        XCTAssertNil(actual)
      }
      do {
        let actual = directPath.extract(from: .direct(42, nil, 43, object))
        XCTAssert(try unwrap(actual) == (42, nil, 43, object))
      }
    }
  }

  #if RELEASE
    func testNonEnumExtract() {
      // This is a bogus CasePath, intended to verify that it just returns nil.
      let path: CasePath<Int, Int> = /{ $0 }

      for _ in 1...2 {
        let actual = path.extract(from: 42)
        XCTAssertNil(actual)
      }
    }
  #endif

  func testOptionalPayload() {
    enum Enum { case int(Int?) }
    let path = /Enum.int
    for _ in 1...2 {
      let actual1 = path.extract(from: .int(.some(42)))
      XCTAssertEqual(actual1, .some(.some(42)))

      let actual2 = path.extract(from: .int(.none))
      XCTAssertEqual(actual2, .some(.none))
    }
  }

  func testAnyPayload() {
    enum Enum { case any(Any) }
    let path = /Enum.any
    for _ in 1...2 {
      XCTAssertEqual(path.extract(from: .any(42)) as? Int, 42)
    }
  }

  func testAnyObjectPayload() {
    class Class {}
    enum Enum { case anyObject(AnyObject) }
    let object = Class()
    let nsObject = NSObject()
    let path = /Enum.anyObject
    for _ in 1...2 {
      XCTAssert(try unwrap(path.extract(from: .anyObject(object))) === object)
      XCTAssert(try unwrap(path.extract(from: .anyObject(nsObject))) === nsObject)
    }
  }

  func testProtocolPayload() {
    struct Error: Swift.Error, Equatable {}
    enum Enum { case error(Swift.Error) }
    let path = /Enum.error
    for _ in 1...2 {
      XCTAssertEqual(path.extract(from: .error(Error())) as? Error, Error())
    }
  }

  func testSubclassPayload() {
    class Superclass {}
    class Subclass: Superclass {}
    enum Enum {
      case superclass(Superclass)
      case subclass(Subclass)
    }
    let superclass = Superclass()
    let subclass = Subclass()
    let superclassPath = /Enum.superclass
    let subclassPath = /Enum.subclass
    for _ in 1...2 {
      XCTAssert(
        try unwrap(superclassPath.extract(from: .superclass(superclass))) === superclass
      )
      XCTAssert(
        try unwrap(superclassPath.extract(from: .superclass(subclass))) === subclass
      )
      XCTAssert(
        try unwrap(subclassPath.extract(from: .subclass(subclass))) === subclass
      )
    }
  }

  func testDefaults() {
    enum Enum { case n(Int, m: Int? = nil, file: String = #file, line: UInt = #line) }
    let path: CasePath<Enum, (Int, Int?, String, UInt)> = /Enum.n
    for _ in 1...2 {
      XCTAssert(
        try unwrap(path.extract(from: .n(42))) == (42, nil, #file, #line)
      )
    }
  }

  func testDifferentMemoryLayouts() {
    struct Struct { var array: [Int] = [1, 2, 3], string: String = "Blob" }
    enum Enum {
      case bool(Bool)
      case int(Int)
      case void(Void)
      case structure(Struct)
      case any(Any)
    }

    let boolPath = /Enum.bool
    let intPath = /Enum.int
    let voidPath = /Enum.void
    let structPath = /Enum.structure
    let anyPath = /Enum.any
    for _ in 1...2 {
      XCTAssertNil(boolPath.extract(from: .int(42)))
      XCTAssertNil(boolPath.extract(from: .void(())))
      XCTAssertNil(boolPath.extract(from: .structure(.init())))
      XCTAssertNil(boolPath.extract(from: .any("Blob")))
      XCTAssertNil(intPath.extract(from: .bool(true)))
      XCTAssertNil(intPath.extract(from: .void(())))
      XCTAssertNil(intPath.extract(from: .structure(.init())))
      XCTAssertNil(intPath.extract(from: .any("Blob")))
      XCTAssertNil(voidPath.extract(from: .bool(true)))
      XCTAssertNil(voidPath.extract(from: .int(42)))
      XCTAssertNil(voidPath.extract(from: .structure(.init())))
      XCTAssertNil(voidPath.extract(from: .any("Blob")))
      XCTAssertNil(structPath.extract(from: .bool(true)))
      XCTAssertNil(structPath.extract(from: .int(42)))
      XCTAssertNil(structPath.extract(from: .void(())))
      XCTAssertNil(structPath.extract(from: .any("Blob")))
      XCTAssertNil(anyPath.extract(from: .bool(true)))
      XCTAssertNil(anyPath.extract(from: .int(42)))
      XCTAssertNil(anyPath.extract(from: .void(())))
      XCTAssertNil(anyPath.extract(from: .structure(.init())))

      XCTAssertNotNil(boolPath.extract(from: .bool(true)))
      XCTAssertNotNil(intPath.extract(from: .int(42)))
      XCTAssertNotNil(voidPath.extract(from: .void(())))
      XCTAssertNotNil(anyPath.extract(from: .any("Blob")))
    }
  }

  func testAssociatedValueIsExistential() {
    enum Enum {
      case proto(TestProtocol)
      case int(Int)
    }

    let protoPath = /Enum.proto
    let intPath = /Enum.int

    for _ in 1...2 {
      XCTAssertNil(protoPath.extract(from: .int(100)))
      XCTAssertEqual(protoPath.extract(from: .proto(100)) as? Int, 100)

      XCTAssertNil(intPath.extract(from: .proto(100)))
      XCTAssertEqual(intPath.extract(from: .int(100)), 100)
    }
  }

  func testContravariantEmbed() {
    enum Enum {
      // associated value type is TestProtocol existential
      case directExistential(TestProtocol)

      // associated value type is single-element tuple (TestProtocol existential)
      case directTuple(label: TestProtocol)

      indirect case indirectExistential(TestProtocol)

      indirect case indirectTuple(label: TestProtocol)

      static let cdeCase = Enum.directExistential(Conformer())
      static let cdtCase = Enum.directTuple(label: Conformer())
      static let cieCase = Enum.indirectExistential(Conformer())
      static let citCase = Enum.indirectTuple(label: Conformer())

      static let ideCase = Enum.directExistential(100)
      static let idtCase = Enum.directTuple(label: 100)
      static let iieCase = Enum.indirectExistential(100)
      static let iitCase = Enum.indirectTuple(label: 100)
    }

    // This is intentionally too big to fit in the three-word buffer of a protocol existential, so
    // that it is stored indirectly.
    struct Conformer: TestProtocol, Equatable {
      var a, b, c, d: Int
      init() {
        (a, b, c, d) = (100, 300, 200, 400)
      }
    }

    let dePath: CasePath<Enum, Conformer> = /Enum.directExistential
    let dtPath: CasePath<Enum, Conformer> = /Enum.directTuple
    let iePath: CasePath<Enum, Conformer> = /Enum.indirectExistential
    let itPath: CasePath<Enum, Conformer> = /Enum.indirectTuple

    for _ in 1...2 {

      XCTAssertNil(dePath.extract(from: .cdtCase))
      XCTAssertNil(dePath.extract(from: .cieCase))
      XCTAssertNil(dePath.extract(from: .citCase))
      XCTAssertNil(dePath.extract(from: .ideCase))
      XCTAssertNil(dePath.extract(from: .idtCase))
      XCTAssertNil(dePath.extract(from: .iieCase))
      XCTAssertNil(dePath.extract(from: .iitCase))
      XCTAssertEqual(dePath.extract(from: .cdeCase), .some(Conformer()))

      XCTAssertNil(dtPath.extract(from: .cdeCase))
      XCTAssertNil(dtPath.extract(from: .cieCase))
      XCTAssertNil(dtPath.extract(from: .citCase))
      XCTAssertNil(dtPath.extract(from: .ideCase))
      XCTAssertNil(dtPath.extract(from: .idtCase))
      XCTAssertNil(dtPath.extract(from: .iieCase))
      XCTAssertNil(dtPath.extract(from: .iitCase))
      XCTAssertEqual(dtPath.extract(from: .cdtCase), .some(Conformer()))

      XCTAssertNil(iePath.extract(from: .cdeCase))
      XCTAssertNil(iePath.extract(from: .cdtCase))
      XCTAssertNil(iePath.extract(from: .citCase))
      XCTAssertNil(iePath.extract(from: .ideCase))
      XCTAssertNil(iePath.extract(from: .idtCase))
      XCTAssertNil(iePath.extract(from: .iieCase))
      XCTAssertNil(iePath.extract(from: .iitCase))
      XCTAssertEqual(iePath.extract(from: .cieCase), .some(Conformer()))

      XCTAssertNil(itPath.extract(from: .cdeCase))
      XCTAssertNil(itPath.extract(from: .cdtCase))
      XCTAssertNil(itPath.extract(from: .cieCase))
      XCTAssertNil(itPath.extract(from: .ideCase))
      XCTAssertNil(itPath.extract(from: .idtCase))
      XCTAssertNil(itPath.extract(from: .iieCase))
      XCTAssertNil(itPath.extract(from: .iitCase))
      XCTAssertEqual(itPath.extract(from: .citCase), .some(Conformer()))
    }
  }

  func testUnreasonableContravariantEmbed() {
    enum Enum {
      case c(TestProtocol, Int)
    }

    // The library doesn't handle this crazy esoteric case, but it detects it and returns nil
    // instead of garbage.
    let path: CasePath<Enum, (Int, Int)> = /Enum.c

    for _ in 1...2 {
      XCTAssertNil(path.extract(from: .c(34, 12)))
    }
  }

  func testPathExtractFromOptionalRoot() {
    enum Authentication {
      case authenticated(token: String)
      case unauthenticated
    }

    let root: Authentication? = .authenticated(token: "deadbeef")
    let path: CasePath<Authentication?, String> = /Authentication.authenticated
    for _ in 1...2 {
      let actual = path.extract(from: root)
      XCTAssertEqual(actual, "deadbeef")
    }
  }

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

    let fooBar = /Foo.bar
    XCTAssertEqual(.bar, fooBar.embed(()))
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
    struct MyError: Equatable, Error {}
    let mySuccess = /Result<String, MyError>.success
    let myFailure = /Result<String, MyError>.failure

    for _ in 1...2 {
      XCTAssertEqual(
        .some("Hello"),
        success.extract(from: .success("Hello"))
      )
      XCTAssertNil(
        failure.extract(from: .success("Hello"))
      )
      XCTAssertEqual(
        .some(MyError()),
        failure.extract(from: .failure(MyError())) as? MyError
      )
      XCTAssertNil(
        success.extract(from: .failure(MyError()))
      )
      XCTAssertEqual(
        .some(MyError()),
        myFailure.extract(from: .failure(MyError()))
      )
      XCTAssertNil(
        mySuccess.extract(from: .failure(MyError()))
      )
    }
  }

  func testIdentity() {
    let id = /Int.self
    XCTAssertEqual(
      .some(42),
      id.extract(from: 42)
    )

    XCTAssertEqual(
      .some(42),
      (/.self)
        .extract(from: 42)
    )
  }

  func testLabeledCases() {
    enum Foo: Equatable {
      case bar(some: Int)
      case bar(none: Int)
    }

    let fooBarSome = /Foo.bar(some:)
    XCTAssertEqual(
      .some(42),
      fooBarSome.extract(from: .bar(some: 42))
    )
    XCTAssertNil(
      fooBarSome.extract(from: .bar(none: 42))
    )
  }

  func testMultiCases() {
    enum Foo {
      case bar(Int, String)
    }

    guard let fizzBuzz = (/Foo.bar).extract(from: .bar(42, "Blob"))
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

  func testMultiMixedCases() {
    enum Foo {
      case bar(Int, buzz: String)
    }

    guard let fizzBuzz = (/Foo.bar).extract(from: .bar(42, buzz: "Blob"))
    else {
      XCTFail()
      return
    }
    XCTAssertEqual(42, fizzBuzz.0)
    XCTAssertEqual("Blob", fizzBuzz.1)
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

  func testCompoundUninhabitedType() {
    // Under Swift 5.1 (Xcode 11.3), this test creates a bogus instance of the tuple
    // `(Never, Never)`, but remarkably, doesn't cause a crash and extracts the correct answer
    // (`nil`).

    enum Enum {
      case nevers(Never, Never)
      case something(Void)
    }

    let path: CasePath<Enum, (Never, Never)> = /Enum.nevers(_:_:)

    for _ in 1...2 {
      XCTAssertNil(path.extract(from: Enum.something(())))
    }
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
      (/Foo.foo .. /Foo.foo .. /Foo.foo .. /Foo.bar).extract(from: .foo(.foo(.foo(.bar(42)))))
    )
    XCTAssertNil(
      (/Foo.foo .. /Foo.foo .. /Foo.foo .. /Foo.bar).extract(from: .foo(.foo(.bar(42))))
    )
  }

  func testExtract() {
    struct MyError: Error {}

    XCTAssertEqual(
      [1],
      [Result.success(1), .success(nil), .failure(MyError())]
        .compactMap(/Result.success .. Optional.some)
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

    enum Foo { case bar(Int, Int) }
    XCTAssertEqual(
      [3],
      [Foo.bar(1, 2)].compactMap(/Foo.bar).map(+)
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
    XCTAssertEqual("Blob", (/Result<String, Error>.success).extract(from: .success("Blob")))
    XCTAssertNil((/Result<String, Error>.failure).extract(from: .success("Blob")))

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

  func testCustomStringConvertible() {
    XCTAssertEqual(
      "\(/Result<String, Error>.success)",
      "CasePath<Result<String, Error>, String>"
    )
  }

  func testOptionalInsideResult() {
    let result: Result<String?, Error> = .success("hello, world")
    let path: CasePath<Result<String?, Error>, String> = /Result.success
    let actual = path.extract(from: result)
    XCTAssertEqual(
      actual,
      "hello, world")

    XCTAssertNil((/Result.failure).extract(from: result))
  }

  func testExtractFromOptionalRoot() {
    enum Foo {
      case foo(String)
      case bar(String)
      case baz
    }

    var opt: Foo? = .foo("blob1")
    XCTAssertEqual("blob1", (/Foo.foo).extract(from: opt))
    XCTAssertNil((/Foo.bar).extract(from: opt))
    XCTAssertNil((/Foo.baz).extract(from: opt))

    opt = .bar("blob2")
    XCTAssertNil((/Foo.foo).extract(from: opt))
    XCTAssertEqual("blob2", (/Foo.bar).extract(from: opt))
    XCTAssertNil((/Foo.baz).extract(from: opt))

    opt = .baz
    XCTAssertNil((/Foo.foo).extract(from: opt))
    XCTAssertNil((/Foo.bar).extract(from: opt))
    XCTAssertNotNil((/Foo.baz).extract(from: opt))

    opt = nil
    XCTAssertNil((/Foo.foo).extract(from: opt))
    XCTAssertNil((/Foo.bar).extract(from: opt))
    XCTAssertNil((/Foo.baz).extract(from: opt))

    let extractExpression: (Foo?) -> String? = /Foo.foo
    XCTAssertNotNil(extractExpression(.some(.foo("blob1"))))
    XCTAssertNil(extractExpression(.some(.bar("blob2"))))
    XCTAssertNil(extractExpression(.some(.baz)))
    XCTAssertNil(extractExpression(nil))

    let voidExtractExpression: (Foo?) -> Void? = /Foo.baz
    XCTAssertNil(voidExtractExpression(.some(.foo("blob1"))))
    XCTAssertNil(voidExtractExpression(.some(.bar("blob2"))))
    XCTAssertNotNil(voidExtractExpression(.some(.baz)))
    XCTAssertNil(voidExtractExpression(nil))
  }

  func testExtractFromOptionalRootWithEmbeddedTagBits() {
    enum E {
      case c1(TestObject)
      case c2(TestObject)
    }

    let o = TestObject()
    let c1Path: CasePath<E?, TestObject> = /E.c1
    let c2Path: CasePath<E?, TestObject> = /E.c2

    func check(_ path: CasePath<E?, TestObject>, _ input: E?, _ expected: TestObject?) {
      let actual = path.extract(from: input)
      XCTAssertEqual(actual, expected)
    }

    for _ in 1...2 {
      check(c1Path, nil, nil)
      check(c1Path, .c1(o), o)
      check(c1Path, .c2(o), nil)
      check(c2Path, nil, nil)
      check(c2Path, .c1(o), nil)
      check(c2Path, .c2(o), o)
    }
  }

  func testExtractionFailureOfOptional() {
    enum Action {
      case child1(Child1)
      case child2(Child2?)
    }
    enum Child1 {
      case a
    }
    enum Child2 {
      case b
    }

    XCTAssertNil((/Action.child1).extract(from: .child2(.b)))
  }
}

private class TestObject: Equatable {
  static func == (lhs: TestObject, rhs: TestObject) -> Bool { lhs === rhs }
}
