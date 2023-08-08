import CasePathsMacros
import MacroSnapshotTesting
import SnapshotTesting
import SwiftSyntaxMacros
import XCTest

final class CasePathMacroTests: XCTestCase {
  override func setUp() {
    super.setUp()
  }

  func testCasePath() throws {
    assertMacroSnapshot(testMacros) {
      #"""
      #casePath(\Foo.bar)
      """#
    } expandsTo: {
      #"""
      CasePaths.CasePath._$case(\Foo.AllCasePaths.bar)
      """#
    }
  }

  func testCasePath_Appending() throws {
    assertMacroSnapshot(testMacros) {
      #"""
      #casePath(\Foo.bar?.baz)
      """#
    } expandsTo: {
      #"""
      CasePaths.CasePath._$case(\Foo.AllCasePaths.bar).appending(path: ._$case(\.baz))
      """#
    }
  }
}
