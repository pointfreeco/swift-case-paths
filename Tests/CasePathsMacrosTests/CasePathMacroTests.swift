import CasePathsMacros
import MacroSnapshotTesting
import SnapshotTesting
import SwiftSyntaxMacros
import XCTest

final class CasePathMacroTests: XCTestCase {
  override func invokeTest() {
    MacroSnapshot.withConfiguration(isRecording: false, macros: testMacros) {
      super.invokeTest()
    }
  }

  func testCasePath() throws {
    assertMacroSnapshot {
      #"""
      #casePath(\Foo.bar)
      """#
    } matches: {
      #"""
      CasePaths.CasePath._$case(\Foo.AllCasePaths.bar)
      """#
    }
  }

  func testCasePath_Appending() throws {
    assertMacroSnapshot {
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
