import Foundation
@_spi(CurrentTestCase) import XCTestDynamicOverlay

/// Asserts that an enum value matches a particular case and modifies the associated value in place.
///
/// - Parameters:
///   - optional: An optional value.
///   - message: An optional description of a failure.
///   - body: A closure that can modify the wrapped value of the given optional.
@available(*, deprecated, message: "Use 'CasePathable.modify' to mutate an expected case, instead.")
public func XCTModify<Wrapped>(
  _ optional: inout Wrapped?,
  _ message: @autoclosure () -> String = "",
  _ body: (inout Wrapped) throws -> Void,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  XCTModify(&optional, case: \.some, message(), body, file: file, line: line)
}

/// Asserts that an enum value matches a particular case and modifies the associated value in place.
///
/// - Parameters:
///   - enum: An enum value.
///   - casePath: A case path that can extract and embed the associated value of a particular case.
///   - message: An optional description of a failure.
///   - body: A closure that can modify the associated value of the given case.
@available(*, deprecated, message: "Use 'CasePathable.modify' to mutate an expected case, instead.")
public func XCTModify<Enum, Case>(
  _ enum: inout Enum,
  case keyPath: CaseKeyPath<Enum, Case>,
  _ message: @autoclosure () -> String = "",
  _ body: (inout Case) throws -> Void,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  _XCTModify(&`enum`, case: AnyCasePath(keyPath), message(), body, file: file, line: line)
}

func _XCTModify<Enum, Case>(
  _ enum: inout Enum,
  case casePath: AnyCasePath<Enum, Case>,
  _ message: @autoclosure () -> String = "",
  _ body: (inout Case) throws -> Void,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  guard var value = casePath.extract(from: `enum`)
  else {
    #if canImport(ObjectiveC)
      _ = XCTCurrentTestCase?.perform(Selector(("setContinueAfterFailure:")), with: false)
    #endif
    let message = message()
    XCTFail(
      """
      XCTModify failed: expected to extract value of type "\(typeName(Case.self))" from \
      "\(typeName(Enum.self))"\
      \(message.isEmpty ? "" : " - " + message) …

        Actual:
          \(`enum`)
      """,
      file: file,
      line: line
    )
    return
  }
  let before = value
  do {
    try body(&value)
  } catch {
    XCTFail("Threw error: \(error)", file: file, line: line)
    return
  }

  if XCTModifyLocals.isExhaustive,
    let isEqual = _isEqual(before, value),
    isEqual
  {
    XCTFail(
      """
      XCTModify failed: expected "\(typeName(Case.self))" value to be modified but it was unchanged.
      """
    )
  }

  `enum` = casePath.embed(value)
}

@_spi(Internals) public enum XCTModifyLocals {
  @TaskLocal public static var isExhaustive = true
}

struct UnwrappingCase: Error {}
