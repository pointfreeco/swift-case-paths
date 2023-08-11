import CasePathsMacros
import MacroSnapshotTesting
import SnapshotTesting
import SwiftSyntaxMacros
import XCTest

final class CasePathableMacroTests: XCTestCase {
  override func invokeTest() {
    MacroSnapshot.withConfiguration(isRecording: false, macros: testMacros) {
      super.invokeTest()
    }
  }

  func testCasePathable() throws {
    assertMacroSnapshot {
      """
      @CasePathable enum Foo {
        case bar
        case baz(Int)
        case fizz(buzz: String)
        case fizzier(Int, buzzier: String)
      }
      """
    } matches: {
      #"""
      enum Foo {
        case bar
        case baz(Int)
        case fizz(buzz: String)
        case fizzier(Int, buzzier: String)

        struct AllCasePaths {
          var bar: CasePaths.CasePath<Foo, Void> {
            CasePaths.CasePath<Foo, Void> ._init(
              embed: {
                .bar
              },
              extract: {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              },
              keyPath: \.bar
            )
          }
          var baz: CasePaths.CasePath<Foo, Int> {
            CasePaths.CasePath<Foo, Int> ._init(
              embed: {
                .baz($0)
              },
              extract: {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              },
              keyPath: \.baz
            )
          }
          var fizz: CasePaths.CasePath<Foo, String> {
            CasePaths.CasePath<Foo, String> ._init(
              embed: {
                .fizz(buzz: $0)
              },
              extract: {
                guard case let .fizz(v0) = $0 else {
                  return nil
                }
                return v0
              },
              keyPath: \.fizz
            )
          }
          var fizzier: CasePaths.CasePath<Foo, (Int, buzzier: String)> {
            CasePaths.CasePath<Foo, (Int, buzzier: String)> ._init(
              embed: {
                .fizzier($0, buzzier: $1)
              },
              extract: {
                guard case let .fizzier(v0, v1) = $0 else {
                  return nil
                }
                return (v0, v1)
              },
              keyPath: \.fizzier
            )
          }
        }
        static var allCasePaths: AllCasePaths { AllCasePaths() }
        var bar: Void? { Self.allCasePaths.bar.extract(from: self) }
        var baz: Int? { Self.allCasePaths.baz.extract(from: self) }
        var fizz: String? { Self.allCasePaths.fizz.extract(from: self) }
        var fizzier: (Int, buzzier: String)? { Self.allCasePaths.fizzier.extract(from: self) }
      }

      extension Foo: CasePaths.CasePathable {
      }
      """#
    }
  }

  func testOverloadedCaseName() throws {
    assertMacroSnapshot {
      """
      @CasePathable enum Foo {
        case bar(Int)
        case bar(int: Int)
      }
      """
    } matches: {
      """
      @CasePathable enum Foo {
        case bar(Int)
             ╰─ 🛑 @CasePathable macro does not allow overloaded case names
        case bar(int: Int)
      }
      """
    }
  }

  func testRequiresEnum() throws {
    assertMacroSnapshot {
      """
      @CasePathable struct Foo {
      }
      """
    } matches: {
      """
      @CasePathable struct Foo {
                    ╰─ 🛑 @CasePathable macro requires 'Foo' to be an enum
      }
      """
    }
  }
}
