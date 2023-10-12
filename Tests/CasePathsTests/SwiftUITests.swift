#if canImport(SwiftUI) && swift(>=5.9)
  import CasePaths
  import SwiftUI
  import XCTest

  @dynamicMemberLookup
  @CasePathable
  enum Status: Equatable {
    case inStock(quantity: Int)
    case outOfStock(isOnBackOrder: Bool)
  }

  final class SwiftUITests: XCTestCase {
    func testBindingDynamicMemberLookup() {
      var _status = Status.inStock(quantity: 21)
      let status = Binding(get: { _status }, set: { _status = $0 })

      Binding(status.inStock).map { $inStock in
        $inStock.wrappedValue *= 2
      }
      XCTAssertEqual(status.wrappedValue, .inStock(quantity: 42))

      status.wrappedValue = .outOfStock(isOnBackOrder: true)

      Binding(status.outOfStock).map { $isOnBackOrder in
        $isOnBackOrder.wrappedValue.toggle()
      }
      XCTAssertEqual(status.wrappedValue, .outOfStock(isOnBackOrder: false))
    }
  }
#endif
