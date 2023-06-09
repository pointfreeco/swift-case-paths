import CasePaths
import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import CasePathsMacros

let testMacros: [String: Macro.Type] = [
  "casePath": CasePathMacro .self,
  "CasePathable": CasePathableMacro .self,
]

final class MacroTests: XCTestCase {
  func test() {
//    @CasePathable
//    enum Action {
//      case buttonTapped
//      case response(Int)
//    }
//    func foo(action: CasePath<Action, Int>) {}
//    foo(action: #casePath(\.))
//
//    var action = Action.response(1)
//    try #casePath(\.response).modify(&action) {
//      $0 += 1
//    }

    /*
     #modify(&$0.destination, case: \.addItem) {
     }
     */
  }

  func testCasePathable() {
    assertMacroExpansion(
      #"""
      @CasePathable
      enum Action {
        case case1
        case case2(Void)
        case case3(Int)
        case case4(id: Int)
        case case5(Int, String)
        case case6(id: Int, String)
        case case7(id: Int, name: String)
        case case8(any Equatable)
        case case9((Int) -> String)
      }
      """#,
      expandedSource: #"""

      enum Action {
        case case1
        case case2(Void)
        case case3(Int)
        case case4(id: Int)
        case case5(Int, String)
        case case6(id: Int, String)
        case case7(id: Int, name: String)
        case case8(any Equatable)
        case case9((Int) -> String)
        var case1: Void? {
          if case .case1 = self {
            ()
        } else {
            nil
        }
        }
        var case2: (Void)? {
          if case let .case2(value) = self {
            value
        } else {
            nil
        }
        }
        var case3: (Int)? {
          if case let .case3(value) = self {
            value
        } else {
            nil
        }
        }
        var case4: (id: Int)? {
          if case let .case4(value) = self {
            value
        } else {
            nil
        }
        }
        var case5: (Int, String)? {
          if case let .case5(value) = self {
            value
        } else {
            nil
        }
        }
        var case6: (id: Int, String)? {
          if case let .case6(value) = self {
            value
        } else {
            nil
        }
        }
        var case7: (id: Int, name: String)? {
          if case let .case7(value) = self {
            value
        } else {
            nil
        }
        }
        var case8: (any Equatable)? {
          if case let .case8(value) = self {
            value
        } else {
            nil
        }
        }
        var case9: ((Int) -> String)? {
          if case let .case9(value) = self {
            value
        } else {
            nil
        }
        }
      }
      """#,
      macros: testMacros
    )
  }

  func testNoAssociatedValue() {
    assertMacroExpansion(
      #"""
      enum Action { case tap }
      let casePath = #casePath(\Action.tap)
      """#,
      expandedSource: #"""
      enum Action {
          case tap
      }
      let casePath = CasePath(embed: {
              .tap($0)
          }, extract: \Action.tap)
      """#,
      macros: testMacros
    )
  }
}
