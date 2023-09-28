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

    func testCasePaths() {
      do {
        let path: CasePath<Enum, _> = #casePath(\.noValue)
        XCTAssertEqual(path, #casePath(\.noValue))
        XCTAssertEqual(path.hashValue, #casePath(\Enum.noValue).hashValue)
        XCTAssertEqual(path.embed(), .noValue)
        XCTAssert(try XCTUnwrap(path.extract(from: .noValue)) == ())

        XCTAssertNotEqual(path, #casePath(\.anotherNoValue))
        XCTAssertNotEqual(path.hashValue, #casePath(\Enum.anotherNoValue).hashValue)
        XCTAssertNotEqual(path.embed(), .anotherNoValue)
        XCTAssertNil(path.extract(from: .anotherNoValue))
      }

      do {
        let path: CasePath<Enum, _> = #casePath(\.oneValue)
        XCTAssertEqual(path, #casePath(\.oneValue))
        XCTAssertEqual(path.hashValue, #casePath(\Enum.oneValue).hashValue)
        XCTAssertEqual(path.embed(42), .oneValue(42))
        XCTAssertEqual(path.extract(from: .oneValue(42)), 42)

        XCTAssertNotEqual(path, #casePath(\.oneLabeledValue))
        XCTAssertNotEqual(path.hashValue, #casePath(\Enum.oneLabeledValue).hashValue)
        XCTAssertNotEqual(path.embed(42), .oneLabeledValue(int: 42))
        XCTAssertNil(path.extract(from: .oneLabeledValue(int: 42)))
      }

      do {
        let path: CasePath<Enum, _> = #casePath(\.oneLabeledValue)
        XCTAssertEqual(path, #casePath(\.oneLabeledValue))
        XCTAssertEqual(path.hashValue, #casePath(\Enum.oneLabeledValue).hashValue)
        XCTAssertEqual(path.embed(42), .oneLabeledValue(int: 42))
        XCTAssertEqual(path.extract(from: .oneLabeledValue(int: 42)), 42)

        XCTAssertNotEqual(path, #casePath(\.oneValue))
        XCTAssertNotEqual(path.hashValue, #casePath(\Enum.oneValue).hashValue)
        XCTAssertNotEqual(path.embed(42), .oneValue(42))
        XCTAssertNil(path.extract(from: .oneValue(42)))
      }

      do {
        let path: CasePath<Enum, _> = #casePath(\.twoValues)
        XCTAssertEqual(path, #casePath(\.twoValues))
        XCTAssertEqual(path.hashValue, #casePath(\Enum.twoValues).hashValue)
        XCTAssertEqual(path.embed((42, "Blob")), .twoValues(42, "Blob"))
        XCTAssert(try XCTUnwrap(path.extract(from: .twoValues(42, "Blob"))) == (42, "Blob"))
      }

      do {
        let path: CasePath<Enum, _> = #casePath(\.twoLabeledValues)
        XCTAssertEqual(path, #casePath(\.twoLabeledValues))
        XCTAssertEqual(path.hashValue, #casePath(\Enum.twoLabeledValues).hashValue)
        XCTAssertEqual(
          path.embed((int: 42, string: "Blob")), .twoLabeledValues(int: 42, string: "Blob")
        )
        XCTAssert(
          try XCTUnwrap(path.extract(from: .twoLabeledValues(int: 42, string: "Blob"))) == (
            int: 42, string: "Blob"
          )
        )
      }

      do {
        let path: CasePath<Enum, _> = #casePath(\.mixedValues)
        XCTAssertEqual(path, #casePath(\.mixedValues))
        XCTAssertEqual(path.hashValue, #casePath(\Enum.mixedValues).hashValue)
        XCTAssertEqual(
          path.embed((int: 42, string: "Blob")), .mixedValues(int: 42, "Blob")
        )
        XCTAssert(
          try XCTUnwrap(path.extract(from: .mixedValues(int: 42, "Blob"))) == (int: 42, "Blob")
        )
      }

      do {
        let path: CasePath<Enum, _> = #casePath(\.recursiveValue)
        XCTAssertEqual(path, #casePath(\.recursiveValue))
        XCTAssertEqual(path.hashValue, #casePath(\Enum.recursiveValue).hashValue)
        XCTAssertEqual(path.embed(.noValue), .recursiveValue(.noValue))
        XCTAssertEqual(path.extract(from: .recursiveValue(.noValue)), .noValue)
      }
    }
  }

  @CasePathable
  private enum Enum: Equatable {
    case noValue
    case anotherNoValue
    case oneValue(Int)
    case oneLabeledValue(int: Int)
    case twoValues(Int, String)
    case twoLabeledValues(int: Int, string: String)
    case mixedValues(int: Int, String)
    indirect case recursiveValue(Enum)
  }
#endif
