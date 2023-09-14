import CasePathsMacros
import MacroTesting
import SwiftSyntaxMacros
import XCTest

final class CasePathMacroTests: XCTestCase {
  override func invokeTest() {
    MacroTesting.withMacroTesting(
      isRecording: false,
      macros: [CasePathMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func testCasePath() {
    assertMacro {
      #"""
      #casePath(\Foo.bar)
      """#
    } matches: {
      #"""
      CasePaths.CasePath._$case(\Foo.AllCasePaths.bar)
      """#
    }
  }

  func testCasePath_Appending() {
    assertMacro {
      #"""
      #casePath(\Foo.bar?.baz)
      """#
    } matches: {
      #"""
      CasePaths.CasePath._$case(\Foo.AllCasePaths.bar).appending(path: ._$case(\.baz))
      """#
    }
  }
}
