import CasePathsMacros
import MacroTesting
import SwiftSyntaxMacros
import XCTest

final class CasePathableMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
      //record: .failed,
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

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            if root.is(\.baz) {
              return \.baz
            }
            if root.is(\.fizz) {
              return \.fizz
            }
            if root.is(\.fizzier) {
              return \.fizzier
            }
            return \.never
          }
          public var bar: CasePaths.AnyCasePath<Foo, Void> {
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
          public var baz: CasePaths.AnyCasePath<Foo, Int> {
            CasePaths.AnyCasePath<Foo, Int>(
              embed: {
                Foo.baz($0)
              },
              extract: {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public var fizz: CasePaths.AnyCasePath<Foo, String> {
            CasePaths.AnyCasePath<Foo, String>(
              embed: {
                Foo.fizz(buzz: $0)
              },
              extract: {
                guard case let .fizz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public var fizzier: CasePaths.AnyCasePath<Foo, (Int, buzzier: String)> {
            CasePaths.AnyCasePath<Foo, (Int, buzzier: String)>(
              embed: {
                Foo.fizzier($0, buzzier: $1)
              },
              extract: {
                guard case let .fizzier(v0, v1) = $0 else {
                  return nil
                }
                return (v0, v1)
              }
            )
          }
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            allCasePaths.append(\.baz)
            allCasePaths.append(\.fizz)
            allCasePaths.append(\.fizzier)
            return allCasePaths.makeIterator()
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
      }
      """#
    }
  }

  func testCasePathable_NoCases() {
    assertMacro {
      """
      @CasePathable enum EnumWithNoCases {}
      """
    } expansion: {
      #"""
      enum EnumWithNoCases {

          public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
              public subscript(root: EnumWithNoCases) -> CasePaths.PartialCaseKeyPath<EnumWithNoCases> {
                  \.never
              }

              public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<EnumWithNoCases>]> {
                  let allCasePaths: [CasePaths.PartialCaseKeyPath<EnumWithNoCases>] = []
                  return allCasePaths.makeIterator()
              }
          }
          public static var allCasePaths: AllCasePaths { AllCasePaths() }}

      extension EnumWithNoCases: CasePaths.CasePathable, CasePaths.CasePathIterable {
      }
      """#
    }
  }

  func testCasePathable_NeverCase() {
    assertMacro {
      """
      @CasePathable enum Foo {
        case bar(Never)
      }
      """
    } expansion: {
      #"""
      enum Foo {
        case bar(Never)

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            return \.never
          }
          public var bar: CasePaths.AnyCasePath<Foo, Never> {
            CasePaths.AnyCasePath<Foo, Never>(
              embed: {  _ -> Foo in
              },
              extract: {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths.makeIterator()
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
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

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            if root.is(\.baz) {
              return \.baz
            }
            return \.never
          }
          public var bar: CasePaths.AnyCasePath<Foo, Int> {
            CasePaths.AnyCasePath<Foo, Int>(
              embed: {
                Foo.bar($0)
              },
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
              embed: {
                Foo.baz($0)
              },
              extract: {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            allCasePaths.append(\.baz)
            return allCasePaths.makeIterator()
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

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            return \.never
          }
          public var bar: CasePaths.AnyCasePath<Foo, Int> {
            CasePaths.AnyCasePath<Foo, Int>(
              embed: {
                Foo.bar($0)
              },
              extract: {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths.makeIterator()
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
      @CasePathable package enum Foo {
        case bar(Int)
      }
      """
    } expansion: {
      #"""
      package enum Foo {
        case bar(Int)

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            return \.never
          }
          public var bar: CasePaths.AnyCasePath<Foo, Int> {
            CasePaths.AnyCasePath<Foo, Int>(
              embed: {
                Foo.bar($0)
              },
              extract: {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths.makeIterator()
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

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            return \.never
          }
          public var bar: CasePaths.AnyCasePath<Foo, Int> {
            CasePaths.AnyCasePath<Foo, Int>(
              embed: {
                Foo.bar($0)
              },
              extract: {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths.makeIterator()
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
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
      #"""
      enum Foo: CasePathable {

          public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
              public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
                  \.never
              }

              public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
                  let allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
                  return allCasePaths.makeIterator()
              }
          }
          public static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathIterable {
      }
      """#
    }
    assertMacro {
      """
      @CasePathable enum Foo: CasePaths.CasePathable {
      }
      """
    } expansion: {
      #"""
      enum Foo: CasePaths.CasePathable {

          public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
              public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
                  \.never
              }

              public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
                  let allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
                  return allCasePaths.makeIterator()
              }
          }
          public static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathIterable {
      }
      """#
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
      #"""
      enum Foo {
        case bar(_ int: Int, _ bool: Bool)

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            return \.never
          }
          public var bar: CasePaths.AnyCasePath<Foo, (Int, Bool)> {
            CasePaths.AnyCasePath<Foo, (Int, Bool)>(
              embed: {
                Foo.bar(_: $0, _: $1)
              },
              extract: {
                guard case let .bar(v0, v1) = $0 else {
                  return nil
                }
                return (v0, v1)
              }
            )
          }
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths.makeIterator()
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
      }
      """#
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
      #"""
      enum Foo {
        case bar(Bar<Self>)

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            return \.never
          }
          public var bar: CasePaths.AnyCasePath<Foo, Bar<Foo>> {
            CasePaths.AnyCasePath<Foo, Bar<Foo>>(
              embed: {
                Foo.bar($0)
              },
              extract: {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths.makeIterator()
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
      }
      """#
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
      #"""
      enum Foo {
        case bar(int: Int = 42, bool: Bool = true)

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            return \.never
          }
          public var bar: CasePaths.AnyCasePath<Foo, (int: Int, bool: Bool)> {
            CasePaths.AnyCasePath<Foo, (int: Int, bool: Bool)>(
              embed: {
                Foo.bar(int: $0, bool: $1)
              },
              extract: {
                guard case let .bar(v0, v1) = $0 else {
                  return nil
                }
                return (v0, v1)
              }
            )
          }
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths.makeIterator()
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
      }
      """#
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
      #"""
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

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            #if os(macOS)
            if root.is(\.macCase) {
              return \.macCase
            }
            if root.is(\.macSecond) {
              return \.macSecond
            }
            #elseif os(iOS)
            if root.is(\.iosCase) {
              return \.iosCase
            }
            #else
            if root.is(\.elseCase) {
              return \.elseCase
            }
            if root.is(\.elseLast) {
              return \.elseLast
            }
            #endif
            #if DEBUG
            #if INNER
            if root.is(\.twoLevelsDeep) {
              return \.twoLevelsDeep
            }
            if root.is(\.twoLevels) {
              return \.twoLevels
            }
            #endif
            #endif
            return \.never
          }
          public var bar: CasePaths.AnyCasePath<Foo, Void> {
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
          public var macCase: CasePaths.AnyCasePath<Foo, Void> {
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
          public var macSecond: CasePaths.AnyCasePath<Foo, Int> {
            CasePaths.AnyCasePath<Foo, Int>(
              embed: {
                Foo.macSecond($0)
              },
              extract: {
                guard case let .macSecond(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          #elseif os(iOS)
          public var iosCase: CasePaths.AnyCasePath<Foo, Void> {
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
          public var elseCase: CasePaths.AnyCasePath<Foo, String> {
            CasePaths.AnyCasePath<Foo, String>(
              embed: {
                Foo.elseCase($0)
              },
              extract: {
                guard case let .elseCase(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public var elseLast: CasePaths.AnyCasePath<Foo, Void> {
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
          public var twoLevelsDeep: CasePaths.AnyCasePath<Foo, Void> {
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
          public var twoLevels: CasePaths.AnyCasePath<Foo, Double> {
            CasePaths.AnyCasePath<Foo, Double>(
              embed: {
                Foo.twoLevels($0)
              },
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
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            #if os(macOS)
            allCasePaths.append(\.macCase)
            allCasePaths.append(\.macSecond)
            #elseif os(iOS)
            allCasePaths.append(\.iosCase)
            #else
            allCasePaths.append(\.elseCase)
            allCasePaths.append(\.elseLast)
            #endif
            #if DEBUG
            #if INNER
            allCasePaths.append(\.twoLevelsDeep)
            allCasePaths.append(\.twoLevels)
            #endif
            #endif
            return allCasePaths.makeIterator()
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
      }
      """#
    }
  }

  func testAvailability() {
    assertMacro {
      """
      @available(iOS, unavailable)
      @CasePathable
      enum Foo {
        case bar
      }
      """
    } expansion: {
      #"""
      @available(iOS, unavailable)
      enum Foo {
        case bar

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            return \.never
          }
          public var bar: CasePaths.AnyCasePath<Foo, Void> {
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
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths.makeIterator()
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      @available(iOS, unavailable) extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
      }
      """#
    }
  }

  func testDocumentation() {
    assertMacro {
      """
      @CasePathable
      enum Foo {

        /// The bar case.
        case bar

        /// The baz case.
        ///
        /// A case for baz.
        case baz

        /**
         The fizz buzz case.

         A case for fizz and buzz.
         */
        case fizz, buzz
      }
      """
    } expansion: {
      #"""
      enum Foo {

        /// The bar case.
        case bar

        /// The baz case.
        ///
        /// A case for baz.
        case baz

        /**
         The fizz buzz case.

         A case for fizz and buzz.
         */
        case fizz, buzz

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            if root.is(\.baz) {
              return \.baz
            }
            if root.is(\.fizz) {
              return \.fizz
            }
            if root.is(\.buzz) {
              return \.buzz
            }
            return \.never
          }
          /// The bar case.
          public var bar: CasePaths.AnyCasePath<Foo, Void> {
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
          /// The baz case.
          ///
          /// A case for baz.
          public var baz: CasePaths.AnyCasePath<Foo, Void> {
            CasePaths.AnyCasePath<Foo, Void>(
              embed: {
                Foo.baz
              },
              extract: {
                guard case .baz = $0 else {
                  return nil
                }
                return ()
              }
            )
          }
          /**
         The fizz buzz case.

         A case for fizz and buzz.
         */
          public var fizz: CasePaths.AnyCasePath<Foo, Void> {
            CasePaths.AnyCasePath<Foo, Void>(
              embed: {
                Foo.fizz
              },
              extract: {
                guard case .fizz = $0 else {
                  return nil
                }
                return ()
              }
            )
          }
          /**
         The fizz buzz case.

         A case for fizz and buzz.
         */
          public var buzz: CasePaths.AnyCasePath<Foo, Void> {
            CasePaths.AnyCasePath<Foo, Void>(
              embed: {
                Foo.buzz
              },
              extract: {
                guard case .buzz = $0 else {
                  return nil
                }
                return ()
              }
            )
          }
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            allCasePaths.append(\.baz)
            allCasePaths.append(\.fizz)
            allCasePaths.append(\.buzz)
            return allCasePaths.makeIterator()
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
      }
      """#
    }
  }

  func testDocumentationIndentationTrimming() {
    assertMacro {
      """
      @CasePathable
      enum Foo {
        // baz
      // case foo
        case bar
      }
      """
    } expansion: {
      #"""
      enum Foo {
        // baz
      // case foo
        case bar

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            return \.never
          }
            // baz
          // case foo
          public var bar: CasePaths.AnyCasePath<Foo, Void> {
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
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths.makeIterator()
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
      }
      """#
    }
  }

  func testComments() {
    assertMacro {
      """
      @CasePathable enum Foo {
        // Comment above case
        case bar
        /*Comment before case*/ case baz(Int)
        case fizz(buzz: String)  // Comment on case
        case fizzier/*Comment in case*/(Int, buzzier: String)
        case fizziest // Comment without associated value
      }
      """
    } expansion: {
      #"""
      enum Foo {
        // Comment above case
        case bar
        /*Comment before case*/ case baz(Int)
        case fizz(buzz: String)  // Comment on case
        case fizzier/*Comment in case*/(Int, buzzier: String)
        case fizziest // Comment without associated value

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
            if root.is(\.bar) {
              return \.bar
            }
            if root.is(\.baz) {
              return \.baz
            }
            if root.is(\.fizz) {
              return \.fizz
            }
            if root.is(\.fizzier) {
              return \.fizzier
            }
            if root.is(\.fizziest) {
              return \.fizziest
            }
            return \.never
          }
          // Comment above case
          public var bar: CasePaths.AnyCasePath<Foo, Void> {
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
          /*Comment before case*/public var baz: CasePaths.AnyCasePath<Foo, Int> {
            CasePaths.AnyCasePath<Foo, Int>(
              embed: {
                Foo.baz($0)
              },
              extract: {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public var fizz: CasePaths.AnyCasePath<Foo, String> {
            CasePaths.AnyCasePath<Foo, String>(
              embed: {
                Foo.fizz(buzz: $0)
              },
              extract: {
                guard case let .fizz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public var fizzier: CasePaths.AnyCasePath<Foo, (Int, buzzier: String)> {
            CasePaths.AnyCasePath<Foo, (Int, buzzier: String)>(
              embed: {
                Foo.fizzier($0, buzzier: $1)
              },
              extract: {
                guard case let .fizzier(v0, v1) = $0 else {
                  return nil
                }
                return (v0, v1)
              }
            )
          }
          public var fizziest: CasePaths.AnyCasePath<Foo, Void> {
            CasePaths.AnyCasePath<Foo, Void>(
              embed: {
                Foo.fizziest
              },
              extract: {
                guard case .fizziest = $0 else {
                  return nil
                }
                return ()
              }
            )
          }
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            allCasePaths.append(\.baz)
            allCasePaths.append(\.fizz)
            allCasePaths.append(\.fizzier)
            allCasePaths.append(\.fizziest)
            return allCasePaths.makeIterator()
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }
      }

      extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
      }
      """#
    }
  }

  func testElementGeneric() {
    assertMacro {
      """
      @CasePathable enum Action<Element> {
        case element(Element)
      }
      """
    } expansion: {
      #"""
      enum Action<Element> {
        case element(Element)

        public struct AllCasePaths: CasePaths.CasePathReflectable, Sendable, Sequence {
          public subscript(root: Action) -> CasePaths.PartialCaseKeyPath<Action> {
            if root.is(\.element) {
              return \.element
            }
            return \.never
          }
          public var element: CasePaths.AnyCasePath<Action, _$Element> {
            CasePaths.AnyCasePath<Action, _$Element>(
              embed: {
                Action.element($0)
              },
              extract: {
                guard case let .element(v0) = $0 else {
                  return nil
                }
                return v0
              }
            )
          }
          public func makeIterator() -> IndexingIterator<[CasePaths.PartialCaseKeyPath<Action>]> {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Action>] = []
            allCasePaths.append(\.element)
            return allCasePaths.makeIterator()
          }
        }
        public static var allCasePaths: AllCasePaths { AllCasePaths() }

        public typealias _$Element = Element
      }

      extension Action: CasePaths.CasePathable, CasePaths.CasePathIterable {
      }
      """#
    }
  }
}
