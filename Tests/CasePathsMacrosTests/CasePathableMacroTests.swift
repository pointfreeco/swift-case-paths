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
    } expansion: {
      """
      enum Foo {
        case bar
        case baz(Int)
        case fizz(buzz: String)
        case fizzier(Int, buzzier: String)

        struct AllCasePaths {
          var bar: CasePaths.AnyCasePath<Foo, Void> {
            CasePaths.AnyCasePath<Foo, Void>(
              embed: {
                Foo.bar
              },
              extract: {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              }
            )
          }
          var baz: CasePaths.AnyCasePath<Foo, Int> {
            CasePaths.AnyCasePath<Foo, Int>(
              embed: Foo.baz,
              extract: {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          var fizz: CasePaths.AnyCasePath<Foo, String> {
            CasePaths.AnyCasePath<Foo, String>(
              embed: Foo.fizz,
              extract: {
                guard case let .fizz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          var fizzier: CasePaths.AnyCasePath<Foo, (Int, buzzier: String)> {
            CasePaths.AnyCasePath<Foo, (Int, buzzier: String)>(
              embed: Foo.fizzier,
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
      }

      extension Foo: CasePaths.CasePathable {
      }
      """
    }
  }

  func testCasePathable_ElementList() {
    assertMacro {
      """
      @CasePathable public enum Foo {
        case bar(Int), baz(String)
      }
      """
    } expansion: {
      """
      public enum Foo {
        case bar(Int), baz(String)

        public struct AllCasePaths {
          public var bar: CasePaths.AnyCasePath<Foo, Int> {
            CasePaths.AnyCasePath<Foo, Int>(
              embed: Foo.bar,
              extract: {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public var baz: CasePaths.AnyCasePath<Foo, String> {
            CasePaths.AnyCasePath<Foo, String>(
              embed: Foo.baz,
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
      }

      extension Foo: CasePaths.CasePathable {
      }
      """
    }
  }

  func testCasePathable_AccessControl() {
    assertMacro {
      """
      @CasePathable public enum Foo {
        case bar(Int)
      }
      """
    } expansion: {
      """
      public enum Foo {
        case bar(Int)

        public struct AllCasePaths {
          public var bar: CasePaths.AnyCasePath<Foo, Int> {
            CasePaths.AnyCasePath<Foo, Int>(
              embed: Foo.bar,
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
      }

      extension Foo: CasePaths.CasePathable {
      }
      """
    }
    assertMacro {
      """
      @CasePathable package enum Foo {
        case bar(Int)
      }
      """
    } expansion: {
      """
      package enum Foo {
        case bar(Int)

        package struct AllCasePaths {
          package var bar: CasePaths.AnyCasePath<Foo, Int> {
            CasePaths.AnyCasePath<Foo, Int>(
              embed: Foo.bar,
              extract: {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
        }
        package static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable {
      }
      """
    }
    assertMacro {
      """
      @CasePathable private enum Foo {
        case bar(Int)
      }
      """
    } expansion: {
      """
      private enum Foo {
        case bar(Int)

        struct AllCasePaths {
          var bar: CasePaths.AnyCasePath<Foo, Int> {
            CasePaths.AnyCasePath<Foo, Int>(
              embed: Foo.bar,
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
      }

      extension Foo: CasePaths.CasePathable {
      }
      """
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
    } diagnostics: {
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
    } diagnostics: {
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
    } expansion: {
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
    } expansion: {
      """
      enum Foo: CasePaths.CasePathable {

          struct AllCasePaths {

          }
          static var allCasePaths: AllCasePaths { AllCasePaths() }
      }
      """
    }
  }

  func testWildcard() {
    assertMacro {
      """
      @CasePathable enum Foo {
        case bar(_ int: Int, _ bool: Bool)
      }
      """
    } expansion: {
      """
      enum Foo {
        case bar(_ int: Int, _ bool: Bool)

        struct AllCasePaths {
          var bar: CasePaths.AnyCasePath<Foo, (Int, Bool)> {
            CasePaths.AnyCasePath<Foo, (Int, Bool)>(
              embed: Foo.bar,
              extract: {
                guard case let .bar(v0, v1) = $0 else {
                  return nil
                }
                return (v0, v1)
              }
            )
          }
        }
        static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable {
      }
      """
    }
  }

  func testSelf() {
    assertMacro {
      """
      @CasePathable enum Foo {
        case bar(Bar<Self>)
      }
      """
    } expansion: {
      """
      enum Foo {
        case bar(Bar<Self>)

        struct AllCasePaths {
          var bar: CasePaths.AnyCasePath<Foo, Bar<Foo>> {
            CasePaths.AnyCasePath<Foo, Bar<Foo>>(
              embed: Foo.bar,
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
      }

      extension Foo: CasePaths.CasePathable {
      }
      """
    }
  }

  func testDefaults() {
    assertMacro {
      """
      @CasePathable enum Foo {
        case bar(int: Int = 42, bool: Bool = true)
      }
      """
    } expansion: {
      """
      enum Foo {
        case bar(int: Int = 42, bool: Bool = true)

        struct AllCasePaths {
          var bar: CasePaths.AnyCasePath<Foo, (int: Int, bool: Bool)> {
            CasePaths.AnyCasePath<Foo, (int: Int, bool: Bool)>(
              embed: Foo.bar,
              extract: {
                guard case let .bar(v0, v1) = $0 else {
                  return nil
                }
                return (v0, v1)
              }
            )
          }
        }
        static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable {
      }
      """
    }
  }

  func testConditionalCompilation() {
    assertMacro {
      """
      @CasePathable enum Foo {
        case bar

        #if os(macOS)
        case macCase
        case macSecond(Int)
        #elseif os(iOS)
        case iosCase
        #else
        case elseCase(String)
        case elseLast
        #endif

        #if DEBUG
        #if INNER
        case twoLevelsDeep
        case twoLevels(Double)
        #endif
        #endif
      }
      """
    } expansion: {
      """
      enum Foo {
        case bar

        #if os(macOS)
        case macCase
        case macSecond(Int)
        #elseif os(iOS)
        case iosCase
        #else
        case elseCase(String)
        case elseLast
        #endif

        #if DEBUG
        #if INNER
        case twoLevelsDeep
        case twoLevels(Double)
        #endif
        #endif

        struct AllCasePaths {
          var bar: CasePaths.AnyCasePath<Foo, Void> {
            CasePaths.AnyCasePath<Foo, Void>(
              embed: {
                Foo.bar
              },
              extract: {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              }
            )
          }
          #if os(macOS)
          var macCase: CasePaths.AnyCasePath<Foo, Void> {
            CasePaths.AnyCasePath<Foo, Void>(
              embed: {
                Foo.macCase
              },
              extract: {
                guard case .macCase = $0 else {
                  return nil
                }
                return ()
              }
            )
          }
          var macSecond: CasePaths.AnyCasePath<Foo, Int> {
            CasePaths.AnyCasePath<Foo, Int>(
              embed: Foo.macSecond,
              extract: {
                guard case let .macSecond(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          #elseif os(iOS)
          var iosCase: CasePaths.AnyCasePath<Foo, Void> {
            CasePaths.AnyCasePath<Foo, Void>(
              embed: {
                Foo.iosCase
              },
              extract: {
                guard case .iosCase = $0 else {
                  return nil
                }
                return ()
              }
            )
          }
          #else
          var elseCase: CasePaths.AnyCasePath<Foo, String> {
            CasePaths.AnyCasePath<Foo, String>(
              embed: Foo.elseCase,
              extract: {
                guard case let .elseCase(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          var elseLast: CasePaths.AnyCasePath<Foo, Void> {
            CasePaths.AnyCasePath<Foo, Void>(
              embed: {
                Foo.elseLast
              },
              extract: {
                guard case .elseLast = $0 else {
                  return nil
                }
                return ()
              }
            )
          }
          #endif
          #if DEBUG
          #if INNER
          var twoLevelsDeep: CasePaths.AnyCasePath<Foo, Void> {
            CasePaths.AnyCasePath<Foo, Void>(
              embed: {
                Foo.twoLevelsDeep
              },
              extract: {
                guard case .twoLevelsDeep = $0 else {
                  return nil
                }
                return ()
              }
            )
          }
          var twoLevels: CasePaths.AnyCasePath<Foo, Double> {
            CasePaths.AnyCasePath<Foo, Double>(
              embed: Foo.twoLevels,
              extract: {
                guard case let .twoLevels(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          #endif
          #endif
        }
        static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable {
      }
      """
    }
  }

}
