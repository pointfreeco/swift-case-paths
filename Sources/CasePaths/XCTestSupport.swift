import Foundation
@_spi(CurrentTestCase) import XCTestDynamicOverlay

#if swift(>=5.9)
  @available(
    iOS, deprecated: 9999,
    message: "Use XCTest's 'XCTUnwrap' with a 'CasePathable' case property, instead"
  )
  @available(
    macOS, deprecated: 9999,
    message: "Use XCTest's 'XCTUnwrap' with a 'CasePathable' case property, instead"
  )
  @available(
    tvOS, deprecated: 9999,
    message: "Use XCTest's 'XCTUnwrap' with a 'CasePathable' case property, instead"
  )
  @available(
    watchOS, deprecated: 9999,
    message: "Use XCTest's 'XCTUnwrap' with a 'CasePathable' case property, instead"
  )
  public func XCTUnwrap<Enum, Case>(
    _ enum: @autoclosure () throws -> Enum,
    case extract: (Enum) -> Case?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) throws -> Case {
    let `enum` = try `enum`()
    guard let value = extract(`enum`)
    else {
      #if canImport(ObjectiveC)
        _ = XCTCurrentTestCase?.perform(Selector(("setContinueAfterFailure:")), with: false)
      #endif
      let message = message()
      XCTFail(
        """
        XCTUnwrap failed: expected to extract value of type "\(typeName(Case.self))" from \
        "\(typeName(Enum.self))"\
        \(message.isEmpty ? "" : " - " + message) …

          Actual:
            \(String(describing: `enum`))
        """,
        file: file,
        line: line
      )
      throw UnwrappingCase()
    }
    return value
  }
#else
  /// Asserts that an enum value matches a particular case and returns the associated value.
  ///
  /// - Parameters:
  ///   - enum: An enum value.
  ///   - extract: A closure that attempts to extract a particular case from the enum. You can
  ///     supply a case path literal here, like '/Enum.case'.
  ///   - message: An optional description of a failure.
  /// - Returns: The unwrapped associated value from the matched case of the enum.
  public func XCTUnwrap<Enum, Case>(
    _ enum: @autoclosure () throws -> Enum,
    case extract: (Enum) -> Case?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) throws -> Case {
    let `enum` = try `enum`()
    guard let value = extract(`enum`)
    else {
      #if canImport(ObjectiveC)
        _ = XCTCurrentTestCase?.perform(Selector(("setContinueAfterFailure:")), with: false)
      #endif
      let message = message()
      XCTFail(
        """
        XCTUnwrap failed: expected to extract value of type "\(typeName(Case.self))" from \
        "\(typeName(Enum.self))"\
        \(message.isEmpty ? "" : " - " + message) …

          Actual:
            \(String(describing: `enum`))
        """,
        file: file,
        line: line
      )
      throw UnwrappingCase()
    }
    return value
  }
#endif

/// Asserts that an enum value matches a particular case and modifies the associated value in place.
///
/// - Parameters:
///   - optional: An optional value.
///   - message: An optional description of a failure.
///   - body: A closure that can modify the wrapped value of the given optional.
public func XCTModify<Wrapped>(
  _ optional: inout Wrapped?,
  _ message: @autoclosure () -> String = "",
  _ body: (inout Wrapped) throws -> Void,
  file: StaticString = #file,
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
public func XCTModify<Enum, Case>(
  _ enum: inout Enum,
  case keyPath: CaseKeyPath<Enum, Case>,
  _ message: @autoclosure () -> String = "",
  _ body: (inout Case) throws -> Void,
  file: StaticString = #file,
  line: UInt = #line
) {
  _XCTModify(&`enum`, case: AnyCasePath(keyPath), message(), body, file: file, line: line)
}

#if swift(>=5.9)
  @available(iOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(macOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(tvOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(watchOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  public func XCTModify<Enum, Case>(
    _ enum: inout Enum,
    case casePath: AnyCasePath<Enum, Case>,
    _ message: @autoclosure () -> String = "",
    _ body: (inout Case) throws -> Void,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    _XCTModify(&`enum`, case: casePath, message(), body, file: file, line: line)
  }
#else
  /// Asserts that an enum value matches a particular case and modifies the associated value in place.
  ///
  /// - Parameters:
  ///   - enum: An enum value.
  ///   - casePath: A case path that can extract and embed the associated value of a particular case.
  ///   - message: An optional description of a failure.
  ///   - body: A closure that can modify the associated value of the given case.
  public func XCTModify<Enum, Case>(
    _ enum: inout Enum,
    case casePath: AnyCasePath<Enum, Case>,
    _ message: @autoclosure () -> String = "",
    _ body: (inout Case) throws -> Void,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    _XCTModify(&`enum`, case: casePath, message(), body, file: file, line: line)
  }
#endif

private func _XCTModify<Enum, Case>(
  _ enum: inout Enum,
  case casePath: AnyCasePath<Enum, Case>,
  _ message: @autoclosure () -> String = "",
  _ body: (inout Case) throws -> Void,
  file: StaticString = #file,
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
      """)
  }

  `enum` = casePath.embed(value)
}

@_spi(Internals) public enum XCTModifyLocals {
  @TaskLocal public static var isExhaustive = true
}

private struct UnwrappingCase: Error {}
