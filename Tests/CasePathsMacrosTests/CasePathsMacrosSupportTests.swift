#if canImport(MacroTesting)
  import CasePathsMacrosSupport
  import MacroTesting
  import SwiftSyntax
  import SwiftSyntaxMacros
  import XCTest

  // A test-only macro built entirely on `CasePathsMacrosSupport`'s public building blocks. It
  // demonstrates the motivating use case: a downstream library can generate the standard
  // `@CasePathable` conformance _and_ extra members (here, an inner `BindingEnumeration` that maps
  // each case's payload to a `Binding`) using a differently named macro.
  private enum CaseBindableMacro {}

  extension CaseBindableMacro: ExtensionMacro {
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
  }

  extension CaseBindableMacro: MemberMacro {
    static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
      // Reuse the standard `@CasePathable` member generation…
      var decls = try CasePathableMacro.expansion(
        of: node,
        providingMembersOf: declaration,
        in: context
      )
      // …then append an inner `BindingEnumeration` derived from the cases.
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

  final class CasePathsMacrosSupportTests: XCTestCase {
    override func invokeTest() {
      withMacroTesting(
        // record: .failed,
        macros: [CaseBindableMacro.self]
      ) {
        super.invokeTest()
      }
    }

    func testCaseBindable() {
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
  }
#endif
