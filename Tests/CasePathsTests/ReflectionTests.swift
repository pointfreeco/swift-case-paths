@_spi(Reflection) import CasePaths
import XCTest

final class ReflectionTests: XCTestCase {
  func testProject() throws {
    struct MyIdentifiable: Identifiable {
      let id = 42
    }
    let success = Result<MyIdentifiable, Error>.success(MyIdentifiable())
    let anyIdentifiable = try XCTUnwrap(EnumMetadata.project(success) as? any Identifiable)
    func id(of identifiable: some Identifiable) -> AnyHashable {
      identifiable.id
    }
    XCTAssertEqual(42, id(of: anyIdentifiable))
  }

  func testProject_Existential() throws {
    struct MyIdentifiable: Identifiable {
      let id = 42
    }
    let success = Result<Any, Error>.success(MyIdentifiable())
    let anyIdentifiable = try XCTUnwrap(EnumMetadata.project(success) as? any Identifiable)
    func id(of identifiable: some Identifiable) -> AnyHashable {
      identifiable.id
    }
    XCTAssertEqual(42, id(of: anyIdentifiable))
  }

  func testProject_Indirect() throws {
    struct MyIdentifiable: Identifiable {
      let id = 42
    }
    enum Enum {
      indirect case indirectCase(MyIdentifiable)
    }
    let indirect = Enum.indirectCase(MyIdentifiable())
    let anyIdentifiable = try XCTUnwrap(EnumMetadata.project(indirect) as? any Identifiable)
    func id(of identifiable: some Identifiable) -> AnyHashable {
      identifiable.id
    }
    XCTAssertEqual(42, id(of: anyIdentifiable))
  }

  func testProject_NoPayload() throws {
    enum Enum {
      case noPayload
    }
    let value = EnumMetadata.project(Enum.noPayload)
    try XCTUnwrap(EnumMetadata.project(value) as? Void)
  }
}
