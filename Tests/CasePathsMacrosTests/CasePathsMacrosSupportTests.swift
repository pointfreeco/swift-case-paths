#if os(macOS) && canImport(MacroTesting) && swift(>=6.2)
  import CasePathsMacrosSupport
  import MacroTesting
  import SwiftSyntax
  import SwiftSyntaxBuilder
  import SwiftSyntaxMacroExpansion
  import SwiftSyntaxMacros
  import Testing

  @Suite(
    .macros([
      "CaseBindable": MacroSpec(
        type: CaseBindableMacro.self,
        conformances: ["CasePathable"]
      ),
      "CasePathable": MacroSpec(
        type: CasePathableMacro.self,
        conformances: ["CasePathable"]
      ),
      "Selection": MacroSpec(
        type: SelectionMacro.self,
        conformances: ["CasePathable"]
      ),
      "ThirdParty": MacroSpec(
        type: ThirdPartyMacro.self,
        conformances: ["CasePathable"]
      ),
    ])
  )
  struct CasePathsMacrosSupportTests {
    @Test func basics() {
      assertMacro {
        """
        @CaseBindable enum Foo {
          case bar
          case baz(Int)
          case fizz(buzz: String)
        }
        """
      } expansion: {
        #"""
        enum Foo {
          case bar
          case baz(Int)
          case fizz(buzz: String)

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
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            allCasePaths.append(\.baz)
            allCasePaths.append(\.fizz)
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
            return nil
          }

          public enum BindingEnumeration {
            case bar
            case baz(SwiftUI.Binding<Int>)
            case fizz(SwiftUI.Binding<String>)
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `with '@CasePathable'`() {
      assertMacro {
        """
        @CaseBindable @CasePathable enum Foo {
          case bar
          case baz(Int)
          case fizz(buzz: String)
        }
        """
      } expansion: {
        #"""
        enum Foo {
          case bar
          case baz(Int)
          case fizz(buzz: String)

          public enum BindingEnumeration {
            case bar
            case baz(SwiftUI.Binding<Int>)
            case fizz(SwiftUI.Binding<String>)
          }

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
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            allCasePaths.append(\.baz)
            allCasePaths.append(\.fizz)
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
            return nil
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test
    func `multiple macros that expand @CasePathable without @CasePathable`() {
      assertMacro {
        """
        @CaseBindable 
        @Selection
        enum Foo {
          case bar
          case baz(Int)
          case fizz(buzz: String)
        }
        """
      } expansion: {
        #"""
        enum Foo {
          case bar
          case baz(Int)
          case fizz(buzz: String)

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
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            allCasePaths.append(\.baz)
            allCasePaths.append(\.fizz)
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
            return nil
          }

          public enum BindingEnumeration {
            case bar
            case baz(SwiftUI.Binding<Int>)
            case fizz(SwiftUI.Binding<String>)
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test
    func `multiple macros that expand @CasePathable with @CasePathable`() {
      assertMacro {
        """
        @CasePathable
        @CaseBindable 
        @Selection
        enum Foo {
          case bar
          case baz(Int)
          case fizz(buzz: String)
        }
        """
      } expansion: {
        #"""
        enum Foo {
          case bar
          case baz(Int)
          case fizz(buzz: String)

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
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.bar)
            allCasePaths.append(\.baz)
            allCasePaths.append(\.fizz)
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
            return nil
          }

          public enum BindingEnumeration {
            case bar
            case baz(SwiftUI.Binding<Int>)
            case fizz(SwiftUI.Binding<String>)
          }
        }

        extension Foo: nonisolated CasePathable {
        }
        """#
      }
    }

    @Test func `3rd party macros are allowed to expand case paths`() {
      assertMacro {
        """
        @ThirdParty
        enum Foo {
          case baz(Int)
        }
        """
      } expansion: {
        #"""
        enum Foo {
          case baz(Int)

          public nonisolated struct AllCasePaths: CasePaths.CasePath, Swift.Hashable, Swift.Sendable {
            public func embed(_ value: Foo) -> Foo {
              value
            }
            public func extract(from root: Foo) -> Foo? {
              root
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
          }

          public nonisolated static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public nonisolated var `case`: CasePaths.PartialCaseKeyPath<Foo> {
            if case .baz = self {
              return \.baz
            }
            return \.never
          }

          public nonisolated static var _allCaseKeyPaths: [CasePaths.PartialCaseKeyPath<Foo>] {
            var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
            allCasePaths.append(\.baz)
            return allCasePaths
          }

          public nonisolated static func caseName(
            for keyPath: CasePaths.PartialCaseKeyPath<Foo>
          ) -> Swift.String? {
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
  }

  private enum SelectionMacro: ExtensionMacro, MemberMacro {
    static func expansion(
      of node: AttributeSyntax,
      attachedTo declaration: some DeclGroupSyntax,
      providingExtensionsOf type: some TypeSyntaxProtocol,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
      try CasePathableMacro.expansion(
        of: node,
        attachedTo: declaration,
        providingExtensionsOf: type,
        conformingTo: protocols,
        in: context
      )
    }
    static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
      try CasePathableMacro.expansion(
        of: node,
        providingMembersOf: declaration,
        in: context
      )
    }
  }

  private enum CaseBindableMacro: MemberMacro, ExtensionMacro {
    static func expansion(
      of node: AttributeSyntax,
      attachedTo declaration: some DeclGroupSyntax,
      providingExtensionsOf type: some TypeSyntaxProtocol,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
      try CasePathableMacro.expansion(
        of: node,
        attachedTo: declaration,
        providingExtensionsOf: type,
        conformingTo: protocols,
        in: context
      )
    }

    static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
      var decls = try CasePathableMacro.expansion(
        of: node,
        providingMembersOf: declaration,
        in: context
      )
      guard let enumDecl = declaration.as(EnumDeclSyntax.self) else { return decls }
      let elements = enumDecl.memberBlock.members
        .flatMap { $0.decl.as(EnumCaseDeclSyntax.self)?.elements ?? [] }
      let cases = elements.map { element -> String in
        let hasPayload = element.parameterClause.map { !$0.parameters.isEmpty } ?? false
        guard hasPayload else { return "case \(element.name.text)" }
        let type = CasePathableMacro.valueType(for: element)
        return "case \(element.name.text)(SwiftUI.Binding<\(type)>)"
      }
      decls.append(
        """
        public enum BindingEnumeration {
        \(raw: cases.joined(separator: "\n"))
        }
        """
      )
      return decls
    }
  }

  private enum ThirdPartyMacro: ExtensionMacro, MemberMacro {
    static func expansion(
      of node: AttributeSyntax,
      attachedTo declaration: some DeclGroupSyntax,
      providingExtensionsOf type: some TypeSyntaxProtocol,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
      try CasePathableMacro.expansion(
        of: node,
        attachedTo: declaration,
        providingExtensionsOf: type,
        conformingTo: protocols,
        in: context
      )
    }
    static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
      try CasePathableMacro.expansion(
        of: node,
        providingMembersOf: declaration,
        in: context
      )
    }
  }
#endif
