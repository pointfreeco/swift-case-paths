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
      #"""
      enum Foo {
        case bar
        case baz(Int)
        case fizz(buzz: String)
        case fizzier(Int, buzzier: String)

        struct AllCasePaths: RandomAccessCollection {
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
          var startIndex: Int {
            0
          }
          var endIndex: Int {
            4
          }
          func index(after i: Int) -> Int {
            i + 1
          }
          func index(before i: Int) -> Int {
            i - 1
          }
          subscript(position: Int) -> PartialCaseKeyPath<Foo> {
            switch position {
            case 0:
              return \Foo.Cases.baz
            case 1:
              return \Foo.Cases.fizz
            case 2:
              return \Foo.Cases.fizzier
            case 3:
              return \Foo.Cases.bar
            default:
              fatalError("Index out of range")
            }
          }
        }
        static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
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
    } expansion: {
      #"""
      public enum Foo {
        case bar(Int), baz(String)

        public struct AllCasePaths: RandomAccessCollection {
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
          public var startIndex: Int {
            0
          }
          public var endIndex: Int {
            2
          }
          public func index(after i: Int) -> Int {
            i + 1
          }
          public func index(before i: Int) -> Int {
            i - 1
          }
          public subscript(position: Int) -> PartialCaseKeyPath<Foo> {
            switch position {
            case 0:
              return \Foo.Cases.bar
            case 1:
              return \Foo.Cases.baz
            default:
              fatalError("Index out of range")
            }
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
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
    } expansion: {
      #"""
      public enum Foo {
        case bar(Int)

        public struct AllCasePaths: RandomAccessCollection {
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
          public var startIndex: Int {
            0
          }
          public var endIndex: Int {
            1
          }
          public func index(after i: Int) -> Int {
            i + 1
          }
          public func index(before i: Int) -> Int {
            i - 1
          }
          public subscript(position: Int) -> PartialCaseKeyPath<Foo> {
            switch position {
            case 0:
              return \Foo.Cases.bar
            default:
              fatalError("Index out of range")
            }
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
      }
      """#
    }
    assertMacro {
      """
      @CasePathable private enum Foo {
        case bar(Int)
      }
      """
    } expansion: {
      #"""
      private enum Foo {
        case bar(Int)

        struct AllCasePaths: RandomAccessCollection {
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
          var startIndex: Int {
            0
          }
          var endIndex: Int {
            1
          }
          func index(after i: Int) -> Int {
            i + 1
          }
          func index(before i: Int) -> Int {
            i - 1
          }
          subscript(position: Int) -> PartialCaseKeyPath<Foo> {
            switch position {
            case 0:
              return \Foo.Cases.bar
            default:
              fatalError("Index out of range")
            }
          }
        }
        static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
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

          struct AllCasePaths: RandomAccessCollection {

              var startIndex: Int {
                  0
              }
              var endIndex: Int {
                  0
              }
              func index(after i: Int) -> Int {
                  i + 1
              }
              func index(before i: Int) -> Int {
                  i - 1
              }
              subscript(position: Int) -> PartialCaseKeyPath<Foo> {
                  switch position {

                  default:
                      fatalError("Index out of range")
                  }
              }
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

          struct AllCasePaths: RandomAccessCollection {

              var startIndex: Int {
                  0
              }
              var endIndex: Int {
                  0
              }
              func index(after i: Int) -> Int {
                  i + 1
              }
              func index(before i: Int) -> Int {
                  i - 1
              }
              subscript(position: Int) -> PartialCaseKeyPath<Foo> {
                  switch position {

                  default:
                      fatalError("Index out of range")
                  }
              }
          }
          static var allCasePaths: AllCasePaths { AllCasePaths() }
      }
      """
    }
  }
}
