#if os(macOS) && canImport(MacroTesting) && swift(>=6.2)
  import CasePathsMacros
  import MacroTesting
  import SwiftSyntaxBuilder
  import SwiftSyntaxMacroExpansion
  import SwiftSyntaxMacros
  import Testing

  @Suite(
    .macros([
      "CasePathable": MacroSpec(
        type: CasePathableMacro.self,
        conformances: ["CasePathable"]
      )
    ])
  )
  struct CasePathableMacroTests {
    @Test func basics() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.bar
              }
              public func extract(from root: Foo) -> Void? {
                guard case .bar = root else {
                  return nil
                }
                return ()
              }
            }
            public var bar: _$bar {
              _$bar()
            }
            public struct _$baz: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Int) -> Foo {
                switch value {
                case _:
                  Foo.baz(value)
                }
              }
              public func extract(from root: Foo) -> Int? {
                guard case let .baz(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var baz: _$baz {
              _$baz()
            }
            public struct _$fizz: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: String) -> Foo {
                switch value {
                case _:
                  Foo.fizz(buzz: value)
                }
              }
              public func extract(from root: Foo) -> String? {
                guard case let .fizz(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var fizz: _$fizz {
              _$fizz()
            }
            public struct _$fizzier: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: (Int, buzzier: String)) -> Foo {
                switch value {
                case (_, _):
                  Foo.fizzier(value.0, buzzier: value.1)
                }
              }
              public func extract(from root: Foo) -> (Int, buzzier: String)? {
                guard case let .fizzier(v0, v1) = root else {
                  return nil
                }
                return (v0, v1)
              }
            }
            public var fizzier: _$fizzier {
              _$fizzier()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            if case .baz = self {
              return \.baz
            }
            if case .fizz = self {
              return \.fizz
            }
            if case .fizzier = self {
              return \.fizzier
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            allCasePaths.append(\.baz)
            allCasePaths.append(\.fizz)
            allCasePaths.append(\.fizzier)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            if keyPath == \.baz {
              return "baz"
            }
            if keyPath == \.fizz {
              return "fizz"
            }
            if keyPath == \.fizzier {
              return "fizzier"
            }
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `uninhabited enum`() {
      assertMacro {
        """
        @CasePathable enum EnumWithNoCases {}
        """
      } expansion: {
        #"""
        enum EnumWithNoCases {

            public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
                public func embed(_ value: EnumWithNoCases) -> EnumWithNoCases {
                }
                public func extract(from root: EnumWithNoCases) -> EnumWithNoCases? {
                }

            }

            public nonisolated static var allCasePaths: AllCasePaths {
                AllCasePaths()
            }

            public nonisolated var `case`: CasePaths.PartialCaseKeyPath<EnumWithNoCases> {
                \.never
            }

            public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<EnumWithNoCases>] {
                let allCasePaths: [CasePaths.PartialCaseKeyPath<EnumWithNoCases>] = []
                return allCasePaths
            }

            public nonisolated static func caseName(
                for keyPath: CasePaths.PartialCaseKeyPath<EnumWithNoCases>
            ) -> Swift.String? {
                return nil
            }
        }

        extension EnumWithNoCases: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `uninhabited case`() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Never) -> Foo {
                switch value {
                case _:
                  Foo.bar(value)
                }
              }
              public func extract(from root: Foo) -> Never? {
                guard case let .bar(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var bar: _$bar {
              _$bar()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `element list`() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Int) -> Foo {
                switch value {
                case _:
                  Foo.bar(value)
                }
              }
              public func extract(from root: Foo) -> Int? {
                guard case let .bar(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var bar: _$bar {
              _$bar()
            }
            public struct _$baz: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: String) -> Foo {
                switch value {
                case _:
                  Foo.baz(value)
                }
              }
              public func extract(from root: Foo) -> String? {
                guard case let .baz(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var baz: _$baz {
              _$baz()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            if case .baz = self {
              return \.baz
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            allCasePaths.append(\.baz)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            if keyPath == \.baz {
              return "baz"
            }
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `access control`() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Int) -> Foo {
                switch value {
                case _:
                  Foo.bar(value)
                }
              }
              public func extract(from root: Foo) -> Int? {
                guard case let .bar(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var bar: _$bar {
              _$bar()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Int) -> Foo {
                switch value {
                case _:
                  Foo.bar(value)
                }
              }
              public func extract(from root: Foo) -> Int? {
                guard case let .bar(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var bar: _$bar {
              _$bar()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Int) -> Foo {
                switch value {
                case _:
                  Foo.bar(value)
                }
              }
              public func extract(from root: Foo) -> Int? {
                guard case let .bar(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var bar: _$bar {
              _$bar()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `overloaded case name`() {
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

    @Test func `struct`() {
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

    @Test func `redundant conformances`() {
      let macros = [
        "CasePathable": MacroSpec(type: CasePathableMacro.self)
      ]
      assertMacro([
        "CasePathable": MacroSpec(type: CasePathableMacro.self)
      ]) {
        """
        @CasePathable enum Foo: CasePathable {
        }
        """
      } expansion: {
        #"""
        enum Foo: CasePathable {

            public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
                public func embed(_ value: Foo) -> Foo {
                }
                public func extract(from root: Foo) -> Foo? {
                }

            }

            public nonisolated static var allCasePaths: AllCasePaths {
                AllCasePaths()
            }

            public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
                \.never
            }

            public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
                let allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
                return allCasePaths
            }

            public nonisolated static func caseName(
                for keyPath: CasePaths.PartialCaseKeyPath<Foo>
            ) -> Swift.String? {
                return nil
            }
        }
        """#
      }
      assertMacro(macros) {
        """
        @CasePathable enum Foo: CasePaths.CasePathable {
        }
        """
      } expansion: {
        #"""
        enum Foo: CasePaths.CasePathable {

            public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
                public func embed(_ value: Foo) -> Foo {
                }
                public func extract(from root: Foo) -> Foo? {
                }

            }

            public nonisolated static var allCasePaths: AllCasePaths {
                AllCasePaths()
            }

            public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
                \.never
            }

            public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
                let allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
                return allCasePaths
            }

            public nonisolated static func caseName(
                for keyPath: CasePaths.PartialCaseKeyPath<Foo>
            ) -> Swift.String? {
                return nil
            }
        }
        """#
      }
      assertMacro {
        """
        @CasePathable enum Foo: CasePathable {
        }
        """
      } expansion: {
        #"""
        enum Foo: CasePathable {

            public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
                public func embed(_ value: Foo) -> Foo {
                }
                public func extract(from root: Foo) -> Foo? {
                }

            }

            public nonisolated static var allCasePaths: AllCasePaths {
                AllCasePaths()
            }

            public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
                \.never
            }

            public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
                let allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
                return allCasePaths
            }

            public nonisolated static func caseName(
                for keyPath: CasePaths.PartialCaseKeyPath<Foo>
            ) -> Swift.String? {
                return nil
            }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func wildcard() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: (Int, Bool)) -> Foo {
                switch value {
                case (_, _):
                  Foo.bar(value.0, value.1)
                }
              }
              public func extract(from root: Foo) -> (Int, Bool)? {
                guard case let .bar(v0, v1) = root else {
                  return nil
                }
                return (v0, v1)
              }
            }
            public var bar: _$bar {
              _$bar()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `capital 'Self'`() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Bar<Foo>) -> Foo {
                switch value {
                case _:
                  Foo.bar(value)
                }
              }
              public func extract(from root: Foo) -> Bar<Foo>? {
                guard case let .bar(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var bar: _$bar {
              _$bar()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func defaults() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: (int: Int, bool: Bool)) -> Foo {
                switch value {
                case (_, _):
                  Foo.bar(int: value.0, bool: value.1)
                }
              }
              public func extract(from root: Foo) -> (int: Int, bool: Bool)? {
                guard case let .bar(v0, v1) = root else {
                  return nil
                }
                return (v0, v1)
              }
            }
            public var bar: _$bar {
              _$bar()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `conditional compilation`() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.bar
              }
              public func extract(from root: Foo) -> Void? {
                guard case .bar = root else {
                  return nil
                }
                return ()
              }
            }
            public var bar: _$bar {
              _$bar()
            }
            #if os(macOS)
            public struct _$macCase: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.macCase
              }
              public func extract(from root: Foo) -> Void? {
                guard case .macCase = root else {
                  return nil
                }
                return ()
              }
            }
            public var macCase: _$macCase {
              _$macCase()
            }
            public struct _$macSecond: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Int) -> Foo {
                switch value {
                case _:
                  Foo.macSecond(value)
                }
              }
              public func extract(from root: Foo) -> Int? {
                guard case let .macSecond(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var macSecond: _$macSecond {
              _$macSecond()
            }
            #elseif os(iOS)
            public struct _$iosCase: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.iosCase
              }
              public func extract(from root: Foo) -> Void? {
                guard case .iosCase = root else {
                  return nil
                }
                return ()
              }
            }
            public var iosCase: _$iosCase {
              _$iosCase()
            }
            #else
            public struct _$elseCase: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: String) -> Foo {
                switch value {
                case _:
                  Foo.elseCase(value)
                }
              }
              public func extract(from root: Foo) -> String? {
                guard case let .elseCase(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var elseCase: _$elseCase {
              _$elseCase()
            }
            public struct _$elseLast: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.elseLast
              }
              public func extract(from root: Foo) -> Void? {
                guard case .elseLast = root else {
                  return nil
                }
                return ()
              }
            }
            public var elseLast: _$elseLast {
              _$elseLast()
            }
            #endif
            #if DEBUG
            #if INNER
            public struct _$twoLevelsDeep: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.twoLevelsDeep
              }
              public func extract(from root: Foo) -> Void? {
                guard case .twoLevelsDeep = root else {
                  return nil
                }
                return ()
              }
            }
            public var twoLevelsDeep: _$twoLevelsDeep {
              _$twoLevelsDeep()
            }
            public struct _$twoLevels: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Double) -> Foo {
                switch value {
                case _:
                  Foo.twoLevels(value)
                }
              }
              public func extract(from root: Foo) -> Double? {
                guard case let .twoLevels(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var twoLevels: _$twoLevels {
              _$twoLevels()
            }
            #endif
            #endif
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            #if os(macOS)
            if case .macCase = self {
              return \.macCase
            }
            if case .macSecond = self {
              return \.macSecond
            }
            #elseif os(iOS)
            if case .iosCase = self {
              return \.iosCase
            }
            #else
            if case .elseCase = self {
              return \.elseCase
            }
            if case .elseLast = self {
              return \.elseLast
            }
            #endif
            #if DEBUG
            #if INNER
            if case .twoLevelsDeep = self {
              return \.twoLevelsDeep
            }
            if case .twoLevels = self {
              return \.twoLevels
            }
            #endif
            #endif
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
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
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            #if os(macOS)
            if keyPath == \.macCase {
              return "macCase"
            }
            if keyPath == \.macSecond {
              return "macSecond"
            }
            #elseif os(iOS)
            if keyPath == \.iosCase {
              return "iosCase"
            }
            #else
            if keyPath == \.elseCase {
              return "elseCase"
            }
            if keyPath == \.elseLast {
              return "elseLast"
            }
            #endif
            #if DEBUG
            #if INNER
            if keyPath == \.twoLevelsDeep {
              return "twoLevelsDeep"
            }
            if keyPath == \.twoLevels {
              return "twoLevels"
            }
            #endif
            #endif
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `availability`() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.bar
              }
              public func extract(from root: Foo) -> Void? {
                guard case .bar = root else {
                  return nil
                }
                return ()
              }
            }
            public var bar: _$bar {
              _$bar()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            return nil
          }
        }

        @available(iOS, unavailable) extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `documentation comments`() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.bar
              }
              public func extract(from root: Foo) -> Void? {
                guard case .bar = root else {
                  return nil
                }
                return ()
              }
            }
            /// The bar case.
            public var bar: _$bar {
              _$bar()
            }
            public struct _$baz: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.baz
              }
              public func extract(from root: Foo) -> Void? {
                guard case .baz = root else {
                  return nil
                }
                return ()
              }
            }
            /// The baz case.
            ///
            /// A case for baz.
            public var baz: _$baz {
              _$baz()
            }
            public struct _$fizz: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.fizz
              }
              public func extract(from root: Foo) -> Void? {
                guard case .fizz = root else {
                  return nil
                }
                return ()
              }
            }
            /**
           The fizz buzz case.

           A case for fizz and buzz.
           */
            public var fizz: _$fizz {
              _$fizz()
            }
            public struct _$buzz: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.buzz
              }
              public func extract(from root: Foo) -> Void? {
                guard case .buzz = root else {
                  return nil
                }
                return ()
              }
            }
            /**
           The fizz buzz case.

           A case for fizz and buzz.
           */
            public var buzz: _$buzz {
              _$buzz()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            if case .baz = self {
              return \.baz
            }
            if case .fizz = self {
              return \.fizz
            }
            if case .buzz = self {
              return \.buzz
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            allCasePaths.append(\.baz)
            allCasePaths.append(\.fizz)
            allCasePaths.append(\.buzz)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            if keyPath == \.baz {
              return "baz"
            }
            if keyPath == \.fizz {
              return "fizz"
            }
            if keyPath == \.buzz {
              return "buzz"
            }
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `documentation indentation trimming`() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.bar
              }
              public func extract(from root: Foo) -> Void? {
                guard case .bar = root else {
                  return nil
                }
                return ()
              }
            }
              // baz
            // case foo
            public var bar: _$bar {
              _$bar()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func comments() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
            }
            public struct _$bar: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.bar
              }
              public func extract(from root: Foo) -> Void? {
                guard case .bar = root else {
                  return nil
                }
                return ()
              }
            }
            // Comment above case
            public var bar: _$bar {
              _$bar()
            }
            public struct _$baz: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Int) -> Foo {
                switch value {
                case _:
                  Foo.baz(value)
                }
              }
              public func extract(from root: Foo) -> Int? {
                guard case let .baz(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            /*Comment before case*/public var baz: _$baz {
              _$baz()
            }
            public struct _$fizz: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: String) -> Foo {
                switch value {
                case _:
                  Foo.fizz(buzz: value)
                }
              }
              public func extract(from root: Foo) -> String? {
                guard case let .fizz(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var fizz: _$fizz {
              _$fizz()
            }
            public struct _$fizzier: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: (Int, buzzier: String)) -> Foo {
                switch value {
                case (_, _):
                  Foo.fizzier(value.0, buzzier: value.1)
                }
              }
              public func extract(from root: Foo) -> (Int, buzzier: String)? {
                guard case let .fizzier(v0, v1) = root else {
                  return nil
                }
                return (v0, v1)
              }
            }
            public var fizzier: _$fizzier {
              _$fizzier()
            }
            public struct _$fizziest: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Void) -> Foo {
                Foo.fizziest
              }
              public func extract(from root: Foo) -> Void? {
                guard case .fizziest = root else {
                  return nil
                }
                return ()
              }
            }
            public var fizziest: _$fizziest {
              _$fizziest()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .bar = self {
              return \.bar
            }
            if case .baz = self {
              return \.baz
            }
            if case .fizz = self {
              return \.fizz
            }
            if case .fizzier = self {
              return \.fizzier
            }
            if case .fizziest = self {
              return \.fizziest
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            allCasePaths.append(\.baz)
            allCasePaths.append(\.fizz)
            allCasePaths.append(\.fizzier)
            allCasePaths.append(\.fizziest)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
            if keyPath == \.bar {
              return "bar"
            }
            if keyPath == \.baz {
              return "baz"
            }
            if keyPath == \.fizz {
              return "fizz"
            }
            if keyPath == \.fizzier {
              return "fizzier"
            }
            if keyPath == \.fizziest {
              return "fizziest"
            }
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func generics() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Action) -> Action {
              value
            }
            public func extract(from root: Action) -> Action? {
              root
            }
            public struct _$element: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: _$Element) -> Action {
                switch value {
                case _:
                  Action.element(value)
                }
              }
              public func extract(from root: Action) -> _$Element? {
                guard case let .element(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var element: _$element {
              _$element()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Action> {
            if case .element = self {
              return \.element
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Action>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Action>] = []
            allCasePaths.append(\.element)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Action>
          ) -> Swift.String? {
            if keyPath == \.element {
              return "element"
            }
            return nil
          }

          public typealias _$Element = Element
        }

        extension Action: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `parent generic`() {
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

            public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Action) -> Action {
                value
              }
              public func extract(from root: Action) -> Action? {
                root
              }
              public struct _$element: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
                public func embed(_ value: _$Element) -> Action {
                  switch value {
                  case _:
                    Action.element(value)
                  }
                }
                public func extract(from root: Action) -> _$Element? {
                  guard case let .element(v0) = root else {
                    return nil
                  }
                  return v0
                }
              }
              public var element: _$element {
                _$element()
              }
            }

            public nonisolated static var allCasePaths: AllCasePaths {
              AllCasePaths()
            }

            public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Action> {
              if case .element = self {
                return \.element
              }
              return \.never
            }

            public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Action>] {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Action>] = []
              allCasePaths.append(\.element)
              return allCasePaths
            }

            public nonisolated static func caseName(
              for keyPath: CasePaths.PartialCaseKeyPath<Action>
            ) -> Swift.String? {
              if keyPath == \.element {
                return "element"
              }
              return nil
            }

            public typealias _$Element = Element
          }
        }

        extension Reducer.Action: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `generic element`() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Action) -> Action {
              value
            }
            public func extract(from root: Action) -> Action? {
              root
            }
            public struct _$element: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Array<_$Element>) -> Action {
                switch value {
                case _:
                  Action.element(value)
                }
              }
              public func extract(from root: Action) -> Array<_$Element>? {
                guard case let .element(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var element: _$element {
              _$element()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Action> {
            if case .element = self {
              return \.element
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Action>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Action>] = []
            allCasePaths.append(\.element)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Action>
          ) -> Swift.String? {
            if keyPath == \.element {
              return "element"
            }
            return nil
          }

          public typealias _$Element = Element
        }

        extension Action: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `many generic cases`() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Action) -> Action {
              value
            }
            public func extract(from root: Action) -> Action? {
              root
            }
            public struct _$element: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Array<_$Element>) -> Action {
                switch value {
                case _:
                  Action.element(value)
                }
              }
              public func extract(from root: Action) -> Array<_$Element>? {
                guard case let .element(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var element: _$element {
              _$element()
            }
            public struct _$secondElement: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: _$Element) -> Action {
                switch value {
                case _:
                  Action.secondElement(value)
                }
              }
              public func extract(from root: Action) -> _$Element? {
                guard case let .secondElement(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var secondElement: _$secondElement {
              _$secondElement()
            }
            public struct _$thirdElement: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: (_$Element, _$Element, Int)) -> Action {
                switch value {
                case (_, _, _):
                  Action.thirdElement(value.0, value.1, value.2)
                }
              }
              public func extract(from root: Action) -> (_$Element, _$Element, Int)? {
                guard case let .thirdElement(v0, v1, v2) = root else {
                  return nil
                }
                return (v0, v1, v2)
              }
            }
            public var thirdElement: _$thirdElement {
              _$thirdElement()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Action> {
            if case .element = self {
              return \.element
            }
            if case .secondElement = self {
              return \.secondElement
            }
            if case .thirdElement = self {
              return \.thirdElement
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Action>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Action>] = []
            allCasePaths.append(\.element)
            allCasePaths.append(\.secondElement)
            allCasePaths.append(\.thirdElement)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Action>
          ) -> Swift.String? {
            if keyPath == \.element {
              return "element"
            }
            if keyPath == \.secondElement {
              return "secondElement"
            }
            if keyPath == \.thirdElement {
              return "thirdElement"
            }
            return nil
          }

          public typealias _$Element = Element
        }

        extension Action: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `trailing commas`() {
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

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Action) -> Action {
              value
            }
            public func extract(from root: Action) -> Action? {
              root
            }
            public struct _$exampleAction: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: (param1: String,
                  param2: String,
                  param3: String)) -> Action {
                switch value {
                case (_, _, _):
                  Action.exampleAction(param1: value.0, param2: value.1, param3: value.2)
                }
              }
              public func extract(from root: Action) -> (param1: String,
                  param2: String,
                  param3: String)? {
                guard case let .exampleAction(v0, v1, v2) = root else {
                  return nil
                }
                return (v0, v1, v2)
              }
            }
            public var exampleAction: _$exampleAction {
              _$exampleAction()
            }
            public struct _$singleParam: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: Int) -> Action {
                switch value {
                case _:
                  Action.singleParam(value: value)
                }
              }
              public func extract(from root: Action) -> Int? {
                guard case let .singleParam(v0) = root else {
                  return nil
                }
                return v0
              }
            }
            public var singleParam: _$singleParam {
              _$singleParam()
            }
            public struct _$multipleWithLabels: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
              public func embed(_ value: (first: String,
                  second: Bool,
                  third: Double)) -> Action {
                switch value {
                case (_, _, _):
                  Action.multipleWithLabels(first: value.0, second: value.1, third: value.2)
                }
              }
              public func extract(from root: Action) -> (first: String,
                  second: Bool,
                  third: Double)? {
                guard case let .multipleWithLabels(v0, v1, v2) = root else {
                  return nil
                }
                return (v0, v1, v2)
              }
            }
            public var multipleWithLabels: _$multipleWithLabels {
              _$multipleWithLabels()
            }
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Action> {
            if case .exampleAction = self {
              return \.exampleAction
            }
            if case .singleParam = self {
              return \.singleParam
            }
            if case .multipleWithLabels = self {
              return \.multipleWithLabels
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Action>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Action>] = []
            allCasePaths.append(\.exampleAction)
            allCasePaths.append(\.singleParam)
            allCasePaths.append(\.multipleWithLabels)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Action>
          ) -> Swift.String? {
            if keyPath == \.exampleAction {
              return "exampleAction"
            }
            if keyPath == \.singleParam {
              return "singleParam"
            }
            if keyPath == \.multipleWithLabels {
              return "multipleWithLabels"
            }
            return nil
          }
        }

        extension Action: nonisolated CasePathable {
        }
        """#
      }
    }

  }
#endif
