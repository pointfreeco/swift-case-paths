import Foundation
@_spi(CurrentTestCase) import XCTestDynamicOverlay

/// Asserts that an enum value matches a particular case and returns the associated value.
///
/// - Parameters:
///   - expression: An enum value.
///   - casePath: The case you want to extract from the enum.
///   - message: An optional description of a failure.
///   - file: The file where the failure occurs. The default is the filename of the test case where
///   you call this function.
///   - line: The line number where the failure occurs. The default is the line number where you
///   call this function.
/// - Returns: Associated value from the matched case on the enum.
public func XCTUnwrap<Root, Case>(
  _ expression: @autoclosure () throws -> Root,
  case extract: (Root) -> Case?,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #filePath,
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

private struct UnwrappingCase: Error {}
