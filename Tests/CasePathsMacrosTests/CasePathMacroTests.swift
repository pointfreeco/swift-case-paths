import CasePathsMacros
import MacroSnapshotTesting
import SnapshotTesting
import SwiftSyntaxMacros
import XCTest

final class CasePathMacroTests: XCTestCase {
  override func setUp() {
    super.setUp()
    isRecording = true
  }
  
  func testCasePath() throws {
    assertMacroSnapshot(testMacros) {
      #"""
      enum Foo {
        case bar(String)
      }
      #casePath(\Foo.bar)
      """#
    } expandsTo: {
      #"""
      CasePaths.CasePath._$case(\Foo.AllCasePaths.bar)
      """#
    }
  }
}
