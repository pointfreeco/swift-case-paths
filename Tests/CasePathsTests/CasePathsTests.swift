#if swift(>=5.9)
  import CasePaths
  import XCTest

  final class CasePathsTests: XCTestCase {
    func testCasePathableProperties() {
      func value<Value>(
        _ root: Enum,
        _ keyPath: KeyPath<Enum, Value?>,
        _ matches: @escaping (Value) -> Bool
      ) -> (root: Enum, keyPath: PartialKeyPath<Enum>, matches: (Any) -> Bool) {
        (root, keyPath, { ($0 as? Value).map(matches) ?? false })
      }

      let values: [(root: Enum, keyPath: PartialKeyPath<Enum>, matches: (Any) -> Bool)] = [
        value(.noValue, \.noValue) { $0 == () },
        value(.oneValue(42), \.oneValue) { $0 == 42 },
        value(.oneLabeledValue(int: 1729), \.oneLabeledValue) { $0 == 1729 },
        value(.twoValues(1, "Blob"), \.twoValues) { $0 == (1, "Blob") },
        value(.twoLabeledValues(int: 2, string: "Blob, Jr."), \.twoLabeledValues) {
          $0 == (int: 2, "Blob, Jr.")
        },
        value(.mixedValues(int: 3, "Blob, Sr."), \.mixedValues) { $0 == (int: 3, "Blob, Sr.") },
        value(.recursiveValue(.noValue), \.recursiveValue) { $0 == .noValue },
      ]

      for (outerOffset, outer) in values.enumerated() {
        for (innerOffset, inner) in values.enumerated() {
          let matches = inner.matches(outer.root[keyPath: inner.keyPath])
          XCTAssert(outerOffset == innerOffset ? matches : !matches)
        }
      }
    }
  }

  @CasePathable
  private enum Enum: Equatable {
    case noValue
    case oneValue(Int)
    case oneLabeledValue(int: Int)
    case twoValues(Int, String)
    case twoLabeledValues(int: Int, string: String)
    case mixedValues(int: Int, String)
    indirect case recursiveValue(Enum)
  }
#endif
