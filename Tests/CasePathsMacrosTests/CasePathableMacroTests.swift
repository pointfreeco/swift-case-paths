#if canImport(MacroTesting) && swift(>=6.2)
  import CasePathsMacros
  import MacroTesting
  import SwiftSyntaxMacros
  import XCTest

  final class CasePathableMacroTests: XCTestCase {
    override func invokeTest() {
      withMacroTesting(
        // record: .failed,
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
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
              CasePaths.AnyCasePath(embed: {
                  Foo.bar
                }) {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              }
            }
            public var baz: CasePaths.AnyCasePath<Foo, Int> {
              CasePaths.AnyCasePath(embed: Foo.baz) {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var fizz: CasePaths.AnyCasePath<Foo, String> {
              CasePaths.AnyCasePath(embed: Foo.fizz) {
                guard case let .fizz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var fizzier: CasePaths.AnyCasePath<Foo, (Int, buzzier: String)> {
              CasePaths.AnyCasePath(embed: Foo.fizzier) {
                guard case let .fizzier(v0, v1) = $0 else {
                  return nil
                }
                return (v0, v1)
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              allCasePaths.append(\.baz)
              allCasePaths.append(\.fizz)
              allCasePaths.append(\.fizzier)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

            public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
                public subscript(root: EnumWithNoCases) -> CasePaths.PartialCaseKeyPath<EnumWithNoCases> {
                    \.never
                }

                public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<EnumWithNoCases>]> {
                    let allCasePaths: [CasePaths.PartialCaseKeyPath<EnumWithNoCases>] = []
                    return allCasePaths.makeIterator()
                }
            }

            public nonisolated static var allCasePaths: AllCasePaths {
                AllCasePaths()
            }
        }

        extension EnumWithNoCases: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
              if root.is(\.bar) {
                return \.bar
              }
              return \.never
            }
            public var bar: CasePaths.AnyCasePath<Foo, Never> {
              CasePaths.AnyCasePath(embed: Foo.bar) {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
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
              CasePaths.AnyCasePath(embed: Foo.bar) {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var baz: CasePaths.AnyCasePath<Foo, String> {
              CasePaths.AnyCasePath(embed: Foo.baz) {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              allCasePaths.append(\.baz)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
              if root.is(\.bar) {
                return \.bar
              }
              return \.never
            }
            public var bar: CasePaths.AnyCasePath<Foo, Int> {
              CasePaths.AnyCasePath(embed: Foo.bar) {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
              if root.is(\.bar) {
                return \.bar
              }
              return \.never
            }
            public var bar: CasePaths.AnyCasePath<Foo, Int> {
              CasePaths.AnyCasePath(embed: Foo.bar) {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
              if root.is(\.bar) {
                return \.bar
              }
              return \.never
            }
            public var bar: CasePaths.AnyCasePath<Foo, Int> {
              CasePaths.AnyCasePath(embed: Foo.bar) {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

            public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
                public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
                    \.never
                }

                public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
                    let allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
                    return allCasePaths.makeIterator()
                }
            }

            public nonisolated static var allCasePaths: AllCasePaths {
                AllCasePaths()
            }
        }

        extension Foo: nonisolated CasePaths.CasePathIterable {
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

            public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
                public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
                    \.never
                }

                public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
                    let allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
                    return allCasePaths.makeIterator()
                }
            }

            public nonisolated static var allCasePaths: AllCasePaths {
                AllCasePaths()
            }
        }

        extension Foo: nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
              if root.is(\.bar) {
                return \.bar
              }
              return \.never
            }
            public var bar: CasePaths.AnyCasePath<Foo, (Int, Bool)> {
              CasePaths.AnyCasePath(embed: Foo.bar) {
                guard case let .bar(v0, v1) = $0 else {
                  return nil
                }
                return (v0, v1)
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
              if root.is(\.bar) {
                return \.bar
              }
              return \.never
            }
            public var bar: CasePaths.AnyCasePath<Foo, Bar<Foo>> {
              CasePaths.AnyCasePath(embed: Foo.bar) {
                guard case let .bar(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
              if root.is(\.bar) {
                return \.bar
              }
              return \.never
            }
            public var bar: CasePaths.AnyCasePath<Foo, (int: Int, bool: Bool)> {
              CasePaths.AnyCasePath(embed: Foo.bar) {
                guard case let .bar(v0, v1) = $0 else {
                  return nil
                }
                return (v0, v1)
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
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
              CasePaths.AnyCasePath(embed: {
                  Foo.bar
                }) {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              }
            }
            #if os(macOS)
            public var macCase: CasePaths.AnyCasePath<Foo, Void> {
              CasePaths.AnyCasePath(embed: {
                  Foo.macCase
                }) {
                guard case .macCase = $0 else {
                  return nil
                }
                return ()
              }
            }
            public var macSecond: CasePaths.AnyCasePath<Foo, Int> {
              CasePaths.AnyCasePath(embed: Foo.macSecond) {
                guard case let .macSecond(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            #elseif os(iOS)
            public var iosCase: CasePaths.AnyCasePath<Foo, Void> {
              CasePaths.AnyCasePath(embed: {
                  Foo.iosCase
                }) {
                guard case .iosCase = $0 else {
                  return nil
                }
                return ()
              }
            }
            #else
            public var elseCase: CasePaths.AnyCasePath<Foo, String> {
              CasePaths.AnyCasePath(embed: Foo.elseCase) {
                guard case let .elseCase(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var elseLast: CasePaths.AnyCasePath<Foo, Void> {
              CasePaths.AnyCasePath(embed: {
                  Foo.elseLast
                }) {
                guard case .elseLast = $0 else {
                  return nil
                }
                return ()
              }
            }
            #endif
            #if DEBUG
            #if INNER
            public var twoLevelsDeep: CasePaths.AnyCasePath<Foo, Void> {
              CasePaths.AnyCasePath(embed: {
                  Foo.twoLevelsDeep
                }) {
                guard case .twoLevelsDeep = $0 else {
                  return nil
                }
                return ()
              }
            }
            public var twoLevels: CasePaths.AnyCasePath<Foo, Double> {
              CasePaths.AnyCasePath(embed: Foo.twoLevels) {
                guard case let .twoLevels(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            #endif
            #endif
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
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

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
              if root.is(\.bar) {
                return \.bar
              }
              return \.never
            }
            public var bar: CasePaths.AnyCasePath<Foo, Void> {
              CasePaths.AnyCasePath(embed: {
                  Foo.bar
                }) {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        @available(iOS, unavailable) extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
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
              CasePaths.AnyCasePath(embed: {
                  Foo.bar
                }) {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              }
            }
            /// The baz case.
            ///
            /// A case for baz.
            public var baz: CasePaths.AnyCasePath<Foo, Void> {
              CasePaths.AnyCasePath(embed: {
                  Foo.baz
                }) {
                guard case .baz = $0 else {
                  return nil
                }
                return ()
              }
            }
            /**
           The fizz buzz case.

           A case for fizz and buzz.
           */
            public var fizz: CasePaths.AnyCasePath<Foo, Void> {
              CasePaths.AnyCasePath(embed: {
                  Foo.fizz
                }) {
                guard case .fizz = $0 else {
                  return nil
                }
                return ()
              }
            }
            /**
           The fizz buzz case.

           A case for fizz and buzz.
           */
            public var buzz: CasePaths.AnyCasePath<Foo, Void> {
              CasePaths.AnyCasePath(embed: {
                  Foo.buzz
                }) {
                guard case .buzz = $0 else {
                  return nil
                }
                return ()
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              allCasePaths.append(\.baz)
              allCasePaths.append(\.fizz)
              allCasePaths.append(\.buzz)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Foo) -> CasePaths.PartialCaseKeyPath<Foo> {
              if root.is(\.bar) {
                return \.bar
              }
              return \.never
            }
              // baz
            // case foo
            public var bar: CasePaths.AnyCasePath<Foo, Void> {
              CasePaths.AnyCasePath(embed: {
                  Foo.bar
                }) {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
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
              CasePaths.AnyCasePath(embed: {
                  Foo.bar
                }) {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              }
            }
            /*Comment before case*/public var baz: CasePaths.AnyCasePath<Foo, Int> {
              CasePaths.AnyCasePath(embed: Foo.baz) {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var fizz: CasePaths.AnyCasePath<Foo, String> {
              CasePaths.AnyCasePath(embed: Foo.fizz) {
                guard case let .fizz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var fizzier: CasePaths.AnyCasePath<Foo, (Int, buzzier: String)> {
              CasePaths.AnyCasePath(embed: Foo.fizzier) {
                guard case let .fizzier(v0, v1) = $0 else {
                  return nil
                }
                return (v0, v1)
              }
            }
            public var fizziest: CasePaths.AnyCasePath<Foo, Void> {
              CasePaths.AnyCasePath(embed: {
                  Foo.fizziest
                }) {
                guard case .fizziest = $0 else {
                  return nil
                }
                return ()
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              allCasePaths.append(\.baz)
              allCasePaths.append(\.fizz)
              allCasePaths.append(\.fizzier)
              allCasePaths.append(\.fizziest)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Action) -> CasePaths.PartialCaseKeyPath<Action> {
              if root.is(\.element) {
                return \.element
              }
              return \.never
            }
            public var element: CasePaths.AnyCasePath<Action, _$Element> {
              CasePaths.AnyCasePath(embed: Action.element) {
                guard case let .element(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Action>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Action>] = []
              allCasePaths.append(\.element)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public typealias _$Element = Element
        }

        extension Action: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
        }
        """#
      }
    }

    func testParentElementGeneric() {
      assertMacro {
        """
        struct Reducer<Element> {
          @CasePathable enum Action {
            case element(Element)
          }
        }
        """
      } expansion: {
        #"""
        struct Reducer<Element> {
          enum Action {
            case element(Element)

            public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
              public subscript(root: Action) -> CasePaths.PartialCaseKeyPath<Action> {
                if root.is(\.element) {
                  return \.element
                }
                return \.never
              }
              public var element: CasePaths.AnyCasePath<Action, _$Element> {
                CasePaths.AnyCasePath(embed: Action.element) {
                  guard case let .element(v0) = $0 else {
                    return nil
                  }
                  return v0
                }
              }
              public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Action>]> {
                var allCasePaths: [CasePaths.PartialCaseKeyPath<Action>] = []
                allCasePaths.append(\.element)
                return allCasePaths.makeIterator()
              }
            }

            public nonisolated static var allCasePaths: AllCasePaths {
              AllCasePaths()
            }

            public typealias _$Element = Element
          }
        }

        extension Reducer.Action: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
        }
        """#
      }
    }

    func testAssociatedValueElementArray() {
      assertMacro {
        """
        @CasePathable enum Action<Element> {
          case element(Array<Element>)
        }
        """
      } expansion: {
        #"""
        enum Action<Element> {
          case element(Array<Element>)

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Action) -> CasePaths.PartialCaseKeyPath<Action> {
              if root.is(\.element) {
                return \.element
              }
              return \.never
            }
            public var element: CasePaths.AnyCasePath<Action, Array<_$Element>> {
              CasePaths.AnyCasePath(embed: Action.element) {
                guard case let .element(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Action>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Action>] = []
              allCasePaths.append(\.element)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public typealias _$Element = Element
        }

        extension Action: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
        }
        """#
      }
    }

    func testMultipleAssociatedValueElement() {
      assertMacro {
        """
        @CasePathable enum Action<Element> {
          case element(Array<Element>)
          case secondElement(Element)
          case thirdElement(Element, Element, Int)
        }
        """
      } expansion: {
        #"""
        enum Action<Element> {
          case element(Array<Element>)
          case secondElement(Element)
          case thirdElement(Element, Element, Int)

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Action) -> CasePaths.PartialCaseKeyPath<Action> {
              if root.is(\.element) {
                return \.element
              }
              if root.is(\.secondElement) {
                return \.secondElement
              }
              if root.is(\.thirdElement) {
                return \.thirdElement
              }
              return \.never
            }
            public var element: CasePaths.AnyCasePath<Action, Array<_$Element>> {
              CasePaths.AnyCasePath(embed: Action.element) {
                guard case let .element(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var secondElement: CasePaths.AnyCasePath<Action, _$Element> {
              CasePaths.AnyCasePath(embed: Action.secondElement) {
                guard case let .secondElement(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var thirdElement: CasePaths.AnyCasePath<Action, (_$Element, _$Element, Int)> {
              CasePaths.AnyCasePath(embed: Action.thirdElement) {
                guard case let .thirdElement(v0, v1, v2) = $0 else {
                  return nil
                }
                return (v0, v1, v2)
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Action>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Action>] = []
              allCasePaths.append(\.element)
              allCasePaths.append(\.secondElement)
              allCasePaths.append(\.thirdElement)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public typealias _$Element = Element
        }

        extension Action: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
        }
        """#
      }
    }

    func testTrailingCommas() {
      assertMacro {
        """
        @CasePathable enum Action {
          case exampleAction(
            param1: String,
            param2: String,
            param3: String,
          )
          case singleParam(
            value: Int,
          )
          case multipleWithLabels(
            first: String,
            second: Bool,
            third: Double,
          )
        }
        """
      } expansion: {
        #"""
        enum Action {
          case exampleAction(
            param1: String,
            param2: String,
            param3: String,
          )
          case singleParam(
            value: Int,
          )
          case multipleWithLabels(
            first: String,
            second: Bool,
            third: Double,
          )

          public nonisolated struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
            public subscript(root: Action) -> CasePaths.PartialCaseKeyPath<Action> {
              if root.is(\.exampleAction) {
                return \.exampleAction
              }
              if root.is(\.singleParam) {
                return \.singleParam
              }
              if root.is(\.multipleWithLabels) {
                return \.multipleWithLabels
              }
              return \.never
            }
            public var exampleAction: CasePaths.AnyCasePath<Action, (param1: String,
                param2: String,
                param3: String)> {
              CasePaths.AnyCasePath(embed: Action.exampleAction) {
                guard case let .exampleAction(v0, v1, v2) = $0 else {
                  return nil
                }
                return (v0, v1, v2)
              }
            }
            public var singleParam: CasePaths.AnyCasePath<Action, Int> {
              CasePaths.AnyCasePath(embed: Action.singleParam) {
                guard case let .singleParam(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var multipleWithLabels: CasePaths.AnyCasePath<Action, (first: String,
                second: Bool,
                third: Double)> {
              CasePaths.AnyCasePath(embed: Action.multipleWithLabels) {
                guard case let .multipleWithLabels(v0, v1, v2) = $0 else {
                  return nil
                }
                return (v0, v1, v2)
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Action>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Action>] = []
              allCasePaths.append(\.exampleAction)
              allCasePaths.append(\.singleParam)
              allCasePaths.append(\.multipleWithLabels)
              return allCasePaths.makeIterator()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Action: nonisolated CasePaths.CasePathable, nonisolated CasePaths.CasePathIterable {
        }
        """#
      }
    }

  }
#endif
