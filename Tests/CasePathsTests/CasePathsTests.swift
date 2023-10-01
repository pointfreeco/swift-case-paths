import CasePaths
import XCTest

final class CasePathsTests: XCTestCase {
  func testCasePaths() {
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
  }
}

@CasePathable enum Foo: Equatable {
  case bar(Bar)
  case baz(Baz)
}
@CasePathable enum Bar: Equatable {
  case int(Int)
}
@CasePathable enum Baz: Equatable {
  case string(String)
}
