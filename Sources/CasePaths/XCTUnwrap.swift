import Foundation
@_spi(CurrentTestCase) import XCTestDynamicOverlay

/// Asserts that an enum value matches a particular case and returns the associated value.
///
/// - Parameters:
///   - expression: An enum value.
///   - extract: A closure that attempts to extract a particular case from the enum. You can supply
///     a case path literal here, like '/Enum.case'.
///   - message: An optional description of a failure.
/// - Returns: The unwrapped associated value from the matched case of the enum.
public func XCTUnwrap<Root, Case>(
  _ expression: @autoclosure () throws -> Root,
  case extract: (Root) -> Case?,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line
) throws -> Case {
  guard let value = try extract(expression())
  else {
    #if canImport(ObjectiveC)
      _ = XCTCurrentTestCase?.perform(Selector(("setContinueAfterFailure:")), with: false)
    #endif
    let message = message()
    XCTFail(
      """
      XCTUnwrap failed: expected non-nil value of type "\(Case.self)"\
      \(message.isEmpty ? "" : " - " + message)
      """,
      file: file,
      line: line
    )
    throw UnwrappingCase()
  }
  return value
}

public func XCTModify<Root, Case, Result>(
  _ root: inout Root,
  case casePath: CasePath<Root, Case>,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line,
  _ body: (inout Case) throws -> Result
) throws -> Result {
  guard var value = casePath.extract(from: root)
  else {
    #if canImport(ObjectiveC)
      _ = XCTCurrentTestCase?.perform(Selector(("setContinueAfterFailure:")), with: false)
    #endif
    let message = message()
    XCTFail(
      """
      XCTModify failed: expected non-nil value of type "\(Case.self)"\
      \(message.isEmpty ? "" : " - " + message)
      """,
      file: file,
      line: line
    )
    throw UnwrappingCase()
  }
  let before = value
  let result = try body(&value)

  if let isEqual = _isEqual(before, value), isEqual {
    XCTFail("""
      XCTModify failed: expected "\(Case.self)" value to be modified but it was unchanged.
      """)
  }

  root = casePath.embed(value)
  return result
}

private struct UnwrappingCase: Error {}
