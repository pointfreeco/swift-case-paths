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

        struct Cases {
          var bar: CasePaths.Case<Foo, Void> {
            CasePaths.Case<Foo, Void> ._$init(
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
          var baz: CasePaths.Case<Foo, Int> {
            CasePaths.Case<Foo, Int> ._$init(
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
          var fizz: CasePaths.Case<Foo, String> {
            CasePaths.Case<Foo, String> ._$init(
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
          var fizzier: CasePaths.Case<Foo, (Int, buzzier: String)> {
            CasePaths.Case<Foo, (Int, buzzier: String)> ._$init(
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
        static var cases: Cases { Cases() }
        var bar: Void? { Self.cases.bar.extract(from: self) }
        var baz: Int? { Self.cases.baz.extract(from: self) }
        var fizz: String? { Self.cases.fizz.extract(from: self) }
        var fizzier: (Int, buzzier: String)? { Self.cases.fizzier.extract(from: self) }
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

        public struct Cases {
          public var bar: CasePaths.Case<Foo, Int> {
            CasePaths.Case<Foo, Int> ._$init(
              embed: {
                .bar($0)
              },
              extract: {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              },
              keyPath: \.bar
            )
          }
          public var baz: CasePaths.Case<Foo, String> {
            CasePaths.Case<Foo, String> ._$init(
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
        }
        public static var cases: Cases { Cases() }
        public var bar: Int? { Self.cases.bar.extract(from: self) }
        public var baz: String? { Self.cases.baz.extract(from: self) }
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

        public struct Cases {
          public var bar: CasePaths.Case<Foo, Int> {
            CasePaths.Case<Foo, Int> ._$init(
              embed: {
                .bar($0)
              },
              extract: {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              },
              keyPath: \.bar
            )
          }
        }
        public static var cases: Cases { Cases() }
        public var bar: Int? { Self.cases.bar.extract(from: self) }
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

        struct Cases {
          var bar: CasePaths.Case<Foo, Int> {
            CasePaths.Case<Foo, Int> ._$init(
              embed: {
                .bar($0)
              },
              extract: {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              },
              keyPath: \.bar
            )
          }
        }
        static var cases: Cases { Cases() }
        var bar: Int? { Self.cases.bar.extract(from: self) }
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

          struct Cases {

          }
          static var cases: Cases { Cases() }
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

          struct Cases {

          }
          static var cases: Cases { Cases() }
      }
      """
    }
  }
}
