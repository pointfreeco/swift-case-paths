import CasePathsMacros
import MacroTesting
import SwiftSyntaxMacros
import XCTest

final class CasePathableMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
      // isRecording: true,
      macros: [CasePathableMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func testCasePathable() {
    assertMacro {
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
          var bar: CasePaths.Case<Foo, Void> {
            CasePaths.Case<Foo, Void>(
              embed: {
                .bar
              },
              extract: {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              }
            )
          }
          var baz: CasePaths.Case<Foo, Int> {
            CasePaths.Case<Foo, Int>(
              embed: {
                .baz($0)
              },
              extract: {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          var fizz: CasePaths.Case<Foo, String> {
            CasePaths.Case<Foo, String>(
              embed: {
                .fizz(buzz: $0)
              },
              extract: {
                guard case let .fizz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          var fizzier: CasePaths.Case<Foo, (Int, buzzier: String)> {
            CasePaths.Case<Foo, (Int, buzzier: String)>(
              embed: {
                .fizzier($0, buzzier: $1)
              },
              extract: {
                guard case let .fizzier(v0, v1) = $0 else {
                  return nil
                }
                return (v0, v1)
              }
            )
          }
        }
        static var allCasePaths: AllCasePaths { AllCasePaths() }
        var bar: Void? { self[keyPath: \CasePaths.Case.bar] }
        var baz: Int? { self[keyPath: \CasePaths.Case.baz] }
        var fizz: String? { self[keyPath: \CasePaths.Case.fizz] }
        var fizzier: (Int, buzzier: String)? { self[keyPath: \CasePaths.Case.fizzier] }
      }

      extension Foo: CasePaths.CasePathable {
      }
      """#
    }
  }

  func testCasePathable_ElementList() {
    assertMacro {
      """
      @CasePathable public enum Foo {
        case bar(Int), baz(String)
      }
      """
    } matches: {
      #"""
      public enum Foo {
        case bar(Int), baz(String)

        public struct AllCasePaths {
          public var bar: CasePaths.Case<Foo, Int> {
            CasePaths.Case<Foo, Int>(
              embed: {
                .bar($0)
              },
              extract: {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public var baz: CasePaths.Case<Foo, String> {
            CasePaths.Case<Foo, String>(
              embed: {
                .baz($0)
              },
              extract: {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
        public var bar: Int? { self[keyPath: \CasePaths.Case.bar] }
        public var baz: String? { self[keyPath: \CasePaths.Case.baz] }
      }

      extension Foo: CasePaths.CasePathable {
      }
      """#
    }
  }

  func testCasePathable_AccessControl() {
    assertMacro {
      """
      @CasePathable public enum Foo {
        case bar(Int)
      }
      """
    } matches: {
      #"""
      public enum Foo {
        case bar(Int)

        public struct AllCasePaths {
          public var bar: CasePaths.Case<Foo, Int> {
            CasePaths.Case<Foo, Int>(
              embed: {
                .bar($0)
              },
              extract: {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
        public var bar: Int? { self[keyPath: \CasePaths.Case.bar] }
      }

      extension Foo: CasePaths.CasePathable {
      }
      """#
    }
    assertMacro {
      """
      @CasePathable private enum Foo {
        case bar(Int)
      }
      """
    } matches: {
      #"""
      private enum Foo {
        case bar(Int)

        struct AllCasePaths {
          var bar: CasePaths.Case<Foo, Int> {
            CasePaths.Case<Foo, Int>(
              embed: {
                .bar($0)
              },
              extract: {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
        }
        static var allCasePaths: AllCasePaths { AllCasePaths() }
        var bar: Int? { self[keyPath: \CasePaths.Case.bar] }
      }

      extension Foo: CasePaths.CasePathable {
      }
      """#
    }
  }

  func testOverloadedCaseName() {
    assertMacro {
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
        case bar(int: Int)
             ┬──
             ╰─ 🛑 '@CasePathable' cannot be applied to overloaded case name 'bar'
      }
      """
    }
  }

  func testRequiresEnum() {
    assertMacro {
      """
      @CasePathable struct Foo {
      }
      """
    } matches: {
      """
      @CasePathable struct Foo {
                    ┬─────
                    ╰─ 🛑 '@CasePathable' cannot be applied to struct type 'Foo'
      }
      """
    }
  }

  func testRedundantConformances() {
    assertMacro {
      """
      @CasePathable enum Foo: CasePathable {
      }
      """
    } matches: {
      """
      enum Foo: CasePathable {

          struct AllCasePaths {

          }
          static var allCasePaths: AllCasePaths { AllCasePaths() }
      }
      """
    }
    assertMacro {
      """
      @CasePathable enum Foo: CasePaths.CasePathable {
      }
      """
    } matches: {
      """
      enum Foo: CasePaths.CasePathable {

          struct AllCasePaths {

          }
          static var allCasePaths: AllCasePaths { AllCasePaths() }
      }
      """
    }
  }
}
