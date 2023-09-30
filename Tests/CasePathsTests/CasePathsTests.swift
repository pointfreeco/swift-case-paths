import CasePaths
import XCTest

final class CasePathsTests: XCTestCase {
  func testCasePaths() {
    var foo: Foo = .bar(.baz(1))

    XCTAssertEqual(foo.bar, .baz(1))
    XCTAssertEqual(foo.bar?.baz, 1)

    XCTAssertEqual(foo[keyPath: \.bar], .baz(1))
    XCTAssertEqual(foo[keyPath: \.bar?.baz], 1)

    foo[keyPath: \.bar] = .baz(42)

    XCTAssertEqual(foo, .bar(.baz(42)))

    foo[keyPath: \.bar.baz] = 1792

    XCTAssertEqual(foo, .bar(.baz(1792)))
  }
}

@CasePathable enum Foo: Equatable { case bar(Bar) }
@CasePathable enum Bar: Equatable { case baz(Int) }
