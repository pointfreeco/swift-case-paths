import CasePaths
import XCTest

final class OptionalPathsTests: XCTestCase {
  func testBasics() {
    let path: OptionalKeyPath<A, Int> = \.b.c.d.some.count

    var a = A(b: .c(C(d: D(count: 42))))
    XCTAssertEqual(path.extract(from: a), 42)

    a.b.modify(\.c.d.some.count) { $0 += 1 }
    XCTAssertEqual(path.extract(from: a), 43)

    a.b.modify(\.c.d) { $0 = nil }
    XCTAssertNil(path.extract(from: a))

    let partialPath: PartialKeyPath = path

    a = A(b: .c(C(d: D(count: 42))))
    XCTAssertEqual(partialPath.extract(from: a) as? Int, 42)

    a.b.modify(\.c.d) { $0 = nil }
    XCTAssertNil(partialPath.extract(from: a))

    XCTAssertNil(partialPath(123))

    XCTAssertNil(partialPath("123"))
  }

  struct A {
    var b: B
  }
  @CasePathable enum B {
    case c(C)
    case z
  }
  struct C {
    var d: D?
  }
  struct D {
    var count = 0
  }
}
