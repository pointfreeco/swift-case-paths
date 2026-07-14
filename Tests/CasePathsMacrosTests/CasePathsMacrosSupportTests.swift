#if canImport(MacroTesting)
  import CasePathsMacrosSupport
  import MacroTesting
  import SwiftSyntax
  import SwiftSyntaxMacros
  import Testing

  @Suite(
    .macros([
      CaseBindableMacro.self,
      CasePathableMacro.self,
      SelectionMacro.self,
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

          public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
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
              return \.never
            }
            public var bar: CasePaths.AnyCasePath<Foo, Void> {
              ._$embed({
                  Foo.bar
                }) {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              }
            }
            public var baz: CasePaths.AnyCasePath<Foo, Int> {
              ._$embed(Foo.baz) {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var fizz: CasePaths.AnyCasePath<Foo, String> {
              ._$embed(Foo.fizz) {
                guard case let .fizz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              allCasePaths.append(\.baz)
              allCasePaths.append(\.fizz)
              return allCasePaths.makeIterator()
            }
          }

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public enum BindingEnumeration {
            case bar
            case baz(SwiftUI.Binding<Int>)
            case fizz(SwiftUI.Binding<String>)
          }
        }

        extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
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

          public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
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
              return \.never
            }
            public var bar: CasePaths.AnyCasePath<Foo, Void> {
              ._$embed({
                  Foo.bar
                }) {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              }
            }
            public var baz: CasePaths.AnyCasePath<Foo, Int> {
              ._$embed(Foo.baz) {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var fizz: CasePaths.AnyCasePath<Foo, String> {
              ._$embed(Foo.fizz) {
                guard case let .fizz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              allCasePaths.append(\.baz)
              allCasePaths.append(\.fizz)
              return allCasePaths.makeIterator()
            }
          }

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
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

          public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
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
              return \.never
            }
            public var bar: CasePaths.AnyCasePath<Foo, Void> {
              ._$embed({
                  Foo.bar
                }) {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              }
            }
            public var baz: CasePaths.AnyCasePath<Foo, Int> {
              ._$embed(Foo.baz) {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var fizz: CasePaths.AnyCasePath<Foo, String> {
              ._$embed(Foo.fizz) {
                guard case let .fizz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              allCasePaths.append(\.baz)
              allCasePaths.append(\.fizz)
              return allCasePaths.makeIterator()
            }
          }

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public enum BindingEnumeration {
            case bar
            case baz(SwiftUI.Binding<Int>)
            case fizz(SwiftUI.Binding<String>)
          }
        }

        extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
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

          public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
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
              return \.never
            }
            public var bar: CasePaths.AnyCasePath<Foo, Void> {
              ._$embed({
                  Foo.bar
                }) {
                guard case .bar = $0 else {
                  return nil
                }
                return ()
              }
            }
            public var baz: CasePaths.AnyCasePath<Foo, Int> {
              ._$embed(Foo.baz) {
                guard case let .baz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public var fizz: CasePaths.AnyCasePath<Foo, String> {
              ._$embed(Foo.fizz) {
                guard case let .fizz(v0) = $0 else {
                  return nil
                }
                return v0
              }
            }
            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Foo>]> {
              var allCasePaths: [CasePaths.PartialCaseKeyPath<Foo>] = []
              allCasePaths.append(\.bar)
              allCasePaths.append(\.baz)
              allCasePaths.append(\.fizz)
              return allCasePaths.makeIterator()
            }
          }

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }

          public enum BindingEnumeration {
            case bar
            case baz(SwiftUI.Binding<Int>)
            case fizz(SwiftUI.Binding<String>)
          }
        }

        extension Foo: CasePaths.CasePathable, CasePaths.CasePathIterable {
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
#endif
