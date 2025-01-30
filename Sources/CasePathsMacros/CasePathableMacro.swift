import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CasePathableMacro {
  static let moduleName = "CasePaths"
  static let casePathTypeName = "AnyCasePath"
}

extension CasePathableMacro: ExtensionMacro {
  public static func expansion<D: DeclGroupSyntax, T: TypeSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    attachedTo declaration: D,
    providingExtensionsOf type: T,
    conformingTo protocols: [TypeSyntax],
    in context: C
  ) throws -> [ExtensionDeclSyntax] {
    // if protocols.isEmpty {
    //   return []
    // }
    guard let enumDecl = declaration.as(EnumDeclSyntax.self)
    else {
      // TODO: Diagnostic?
      return []
    }
    var conformances: [String] = []
    if let inheritanceClause = enumDecl.inheritanceClause {
      for type in ["CasePathable", "CasePathIterable"] {
        if !inheritanceClause.inheritedTypes.contains(where: {
          [type, type.qualified].contains($0.type.trimmedDescription)
        }) {
          conformances.append("\(moduleName).\(type)")
        }
      }
    } else {
      conformances = ["CasePathable", "CasePathIterable"].qualified
    }
    guard !conformances.isEmpty else { return [] }
    return [
      DeclSyntax(
        """
        \(declaration.attributes.availability)extension \(type.trimmed): \
        \(raw: conformances.joined(separator: ", ")) {}
        """
      )
      .cast(ExtensionDeclSyntax.self)
    ]
  }
}

extension CasePathableMacro: MemberMacro {
  public static func expansion<
    Declaration: DeclGroupSyntax, Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    providingMembersOf declaration: Declaration,
    in context: Context
  ) throws -> [DeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self)
    else {
      throw DiagnosticsError(
        diagnostics: [
          CasePathableMacroDiagnostic
            .notAnEnum(declaration)
            .diagnose(at: declaration.keyword)
        ]
      )
    }
    let enumName = enumDecl.name.trimmed

    let enumCaseDecls = enumDecl.memberBlock.members
      .flatMap { $0.decl.as(EnumCaseDeclSyntax.self)?.elements ?? [] }

    var seenCaseNames: Set<String> = []
    for enumCaseDecl in enumCaseDecls {
      let name = enumCaseDecl.name.text
      if seenCaseNames.contains(name) {
        throw DiagnosticsError(
          diagnostics: [
            CasePathableMacroDiagnostic.overloadedCaseName(name).diagnose(
              at: Syntax(enumCaseDecl.name))
          ]
        )
      }
      seenCaseNames.insert(name)
    }

    let selfRewriter = SelfRewriter(selfEquivalent: enumName)
    let memberBlock = selfRewriter.rewrite(enumDecl.memberBlock).cast(MemberBlockSyntax.self)
    let rootSubscriptCases = generateCases(from: memberBlock.members, enumName: enumName) {
      "if root.is(\\.\(raw: $0.name.text)) { return \\.\(raw: $0.name.text) }"
    }
    let elementRewriter = ElementRewriter()
    let casePaths = generateDeclSyntax(from: memberBlock.members, enumName: enumName).map {
      elementRewriter.rewrite($0)
    }
    let allCases = generateCases(from: memberBlock.members, enumName: enumName) {
      "allCasePaths.append(\\.\(raw: $0.name.text))"
    }

    let subscriptReturn = allCases.isEmpty ? #"\.never"# : #"return \.never"#

    var decls: [DeclSyntax] = [
      """
      public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
      public subscript(root: \(enumName)) -> CasePaths.PartialCaseKeyPath<\(enumName)> {
      \(raw: rootSubscriptCases.map { "\($0.description)\n" }.joined())\(raw: subscriptReturn)
      }
      \(raw: casePaths.map(\.description).joined(separator: "\n"))
      public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<\(enumName)>]> {
      \(raw: allCases.isEmpty ? "let" : "var") allCasePaths: \
      [CasePaths.PartialCaseKeyPath<\(enumName)>] = []\
      \(raw: allCases.map { "\n\($0.description)" }.joined())
      return allCasePaths.makeIterator()
      }
      }
      public static var allCasePaths: AllCasePaths { AllCasePaths() }
      """
    ]

    if elementRewriter.didRewriteElement {
      decls.append("public typealias _$Element = Element")
    }

    return decls
  }

  static func generateCases(
    from elements: MemberBlockItemListSyntax,
    enumName: TokenSyntax,
    body: (EnumCaseElementSyntax) -> DeclSyntax
  ) -> [DeclSyntax] {
    elements.flatMap {
      if let decl = $0.decl.as(EnumCaseDeclSyntax.self) {
        return decl.elements.map(body)
      }
      if let ifConfigDecl = $0.decl.as(IfConfigDeclSyntax.self) {
        let ifClauses = ifConfigDecl.clauses.flatMap { decl -> [DeclSyntax] in
          guard let elements = decl.elements?.as(MemberBlockItemListSyntax.self) else {
            return []
          }
          let title = "\(decl.poundKeyword.text) \(decl.condition?.description ?? "")"
          return ["\(raw: title)"]
            + generateCases(from: elements, enumName: enumName, body: body)
        }
        return ifClauses + ["#endif"]
      }
      return []
    }
  }

  static func generateDeclSyntax(
    from elements: MemberBlockItemListSyntax,
    enumName: TokenSyntax
  ) -> [DeclSyntax] {
    elements.flatMap {
      if let decl = $0.decl.as(EnumCaseDeclSyntax.self) {
        return generateDeclSyntax(from: decl, enumName: enumName)
      }
      if let ifConfigDecl = $0.decl.as(IfConfigDeclSyntax.self) {
        let ifClauses = ifConfigDecl.clauses.flatMap { decl -> [DeclSyntax] in
          guard let elements = decl.elements?.as(MemberBlockItemListSyntax.self) else {
            return []
          }
          let title = "\(decl.poundKeyword.text) \(decl.condition?.description ?? "")"
          return ["\(raw: title)"]
            + generateDeclSyntax(from: elements, enumName: enumName)
        }
        return ifClauses + ["#endif"]
      }
      return []
    }
  }

  static func generateDeclSyntax(
    from decl: EnumCaseDeclSyntax,
    enumName: TokenSyntax
  ) -> [DeclSyntax] {
    decl.elements.map {
      let caseName = $0.name.trimmed
      let associatedValueName = $0.trimmedTypeDescription
      let hasPayload = $0.parameterClause.map { !$0.parameters.isEmpty } ?? false
      let embed: DeclSyntax = hasPayload ? "\(enumName).\(caseName)" : "{ \(enumName).\(caseName) }"
      let bindingNames: String
      let returnName: String
      if hasPayload, let associatedValue = $0.parameterClause {
        let parameterNames = (0..<associatedValue.parameters.count)
          .map { "v\($0)" }
          .joined(separator: ", ")
        bindingNames = "(\(parameterNames))"
        returnName = associatedValue.parameters.count == 1 ? parameterNames : bindingNames
      } else {
        bindingNames = ""
        returnName = "()"
      }
      let leadingTriviaLines = decl.leadingTrivia.description
        .drop(while: \.isNewline)
        .split(separator: "\n", omittingEmptySubsequences: false)
      let indent =
        leadingTriviaLines
        .compactMap { $0.isEmpty ? nil : $0.prefix(while: \.isWhitespace).count }
        .min(by: { (lhs: Int, rhs: Int) -> Bool in lhs < rhs })
        ?? 0
      let leadingTrivia =
        leadingTriviaLines
        .map { String($0.dropFirst(indent)) }
        .joined(separator: "\n")
        .trimmingSuffix(while: { $0.isWhitespace && !$0.isNewline })
      return """
        \(raw: leadingTrivia)public var \(caseName): \
        \(raw: casePathTypeName.qualified)<\(enumName), \(raw: associatedValueName)> {
        ._$embed(\(embed)) {
        guard case\(raw: hasPayload ? " let" : "").\(caseName)\(raw: bindingNames) = $0 else { \
        return nil \
        }
        return \(raw: returnName)
        }
        }
        """
    }
  }
}

enum CasePathableMacroDiagnostic {
  case notAnEnum(DeclGroupSyntax)
  case overloadedCaseName(String)
}

extension CasePathableMacroDiagnostic: DiagnosticMessage {
  var message: String {
    switch self {
    case let .notAnEnum(decl):
      return """
        '@CasePathable' cannot be applied to\
        \(decl.keywordDescription.map { " \($0)" } ?? "") type\
        \(decl.nameDescription.map { " '\($0)'" } ?? "")
        """
    case let .overloadedCaseName(name):
      return """
        '@CasePathable' cannot be applied to overloaded case name '\(name)'
        """
    }
  }

  var diagnosticID: MessageID {
    switch self {
    case .notAnEnum:
      return MessageID(domain: "MetaEnumDiagnostic", id: "notAnEnum")
    case .overloadedCaseName:
      return MessageID(domain: "MetaEnumDiagnostic", id: "overloadedCaseName")
    }
  }

  var severity: DiagnosticSeverity {
    switch self {
    case .notAnEnum:
      return .error
    case .overloadedCaseName:
      return .error
    }
  }

  func diagnose(at node: Syntax) -> Diagnostic {
    Diagnostic(node: node, message: self)
  }
}

extension AttributeListSyntax {
  var availability: AttributeListSyntax? {
    var elements = [AttributeListSyntax.Element]()
    for element in self {
      if let availability = element.availability {
        elements.append(availability)
      }
    }
    if elements.isEmpty {
      return nil
    }
    return AttributeListSyntax(elements)
  }
}

extension AttributeListSyntax.Element {
  var availability: AttributeListSyntax.Element? {
    switch self {
    case .attribute(let attribute):
      if let availability = attribute.availability {
        return .attribute(availability)
      }
    case .ifConfigDecl(let ifConfig):
      if let availability = ifConfig.availability {
        return .ifConfigDecl(availability)
      }
    @unknown default: return nil
    }
    return nil
  }
}

extension AttributeSyntax {
  var availability: AttributeSyntax? {
    if attributeName.identifier == "available" {
      return self
    } else {
      return nil
    }
  }
}

extension IfConfigClauseSyntax {
  var availability: IfConfigClauseSyntax? {
    if let availability = elements?.availability {
      return with(\.elements, availability)
    } else {
      return nil
    }
  }

  var clonedAsIf: IfConfigClauseSyntax {
    detached.with(\.poundKeyword, .poundIfToken())
  }
}

extension IfConfigClauseSyntax.Elements {
  var availability: IfConfigClauseSyntax.Elements? {
    switch self {
    case .attributes(let attributes):
      if let availability = attributes.availability {
        return .attributes(availability)
      } else {
        return nil
      }
    default:
      return nil
    }
  }
}

extension IfConfigDeclSyntax {
  var availability: IfConfigDeclSyntax? {
    var elements = [IfConfigClauseListSyntax.Element]()
    for clause in clauses {
      if let availability = clause.availability {
        if elements.isEmpty {
          elements.append(availability.clonedAsIf)
        } else {
          elements.append(availability)
        }
      }
    }
    if elements.isEmpty {
      return nil
    } else {
      return with(\.clauses, IfConfigClauseListSyntax(elements))
    }
  }
}

extension DeclGroupSyntax {
  var keyword: Syntax {
    switch self {
    case let syntax as ActorDeclSyntax:
      return Syntax(syntax.actorKeyword)
    case let syntax as ClassDeclSyntax:
      return Syntax(syntax.classKeyword)
    case let syntax as ExtensionDeclSyntax:
      return Syntax(syntax.extensionKeyword)
    case let syntax as ProtocolDeclSyntax:
      return Syntax(syntax.protocolKeyword)
    case let syntax as StructDeclSyntax:
      return Syntax(syntax.structKeyword)
    case let syntax as EnumDeclSyntax:
      return Syntax(syntax.enumKeyword)
    default:
      return Syntax(self)
    }
  }

  var keywordDescription: String? {
    switch self {
    case let syntax as ActorDeclSyntax:
      return syntax.actorKeyword.trimmedDescription
    case let syntax as ClassDeclSyntax:
      return syntax.classKeyword.trimmedDescription
    case let syntax as ExtensionDeclSyntax:
      return syntax.extensionKeyword.trimmedDescription
    case let syntax as ProtocolDeclSyntax:
      return syntax.protocolKeyword.trimmedDescription
    case let syntax as StructDeclSyntax:
      return syntax.structKeyword.trimmedDescription
    case let syntax as EnumDeclSyntax:
      return syntax.enumKeyword.trimmedDescription
    default:
      return nil
    }
  }

  var nameDescription: String? {
    switch self {
    case let syntax as ActorDeclSyntax:
      return syntax.name.trimmedDescription
    case let syntax as ClassDeclSyntax:
      return syntax.name.trimmedDescription
    case let syntax as ExtensionDeclSyntax:
      return syntax.extendedType.trimmedDescription
    case let syntax as ProtocolDeclSyntax:
      return syntax.name.trimmedDescription
    case let syntax as StructDeclSyntax:
      return syntax.name.trimmedDescription
    case let syntax as EnumDeclSyntax:
      return syntax.name.trimmedDescription
    default:
      return nil
    }
  }
}

extension EnumCaseElementListSyntax.Element {
  var trimmedTypeDescription: String {
    if var associatedValue = self.parameterClause, !associatedValue.parameters.isEmpty {
      if associatedValue.parameters.count == 1,
        let type = associatedValue.parameters.first?.type.trimmed
      {
        return type.is(SomeOrAnyTypeSyntax.self)
          ? "(\(type))"
          : "\(type)"
      } else {
        for index in associatedValue.parameters.indices {
          associatedValue.parameters[index].type.trailingTrivia = ""
          associatedValue.parameters[index].defaultValue = nil
          if associatedValue.parameters[index].firstName?.tokenKind == .wildcard {
            associatedValue.parameters[index].colon = nil
            associatedValue.parameters[index].firstName = nil
            associatedValue.parameters[index].secondName = nil
          }
        }
        return "(\(associatedValue.parameters.trimmed))"
      }
    } else {
      return "Void"
    }
  }
}

extension SyntaxStringInterpolation {
  mutating func appendInterpolation<Node: SyntaxProtocol>(_ node: Node?) {
    if let node {
      self.appendInterpolation(node)
    }
  }
}

extension TypeSyntax {
  var identifier: String? {
    for token in tokens(viewMode: .all) {
      switch token.tokenKind {
      case .identifier(let identifier):
        return identifier
      default:
        break
      }
    }
    return nil
  }
}

final class SelfRewriter: SyntaxRewriter {
  let selfEquivalent: TokenSyntax

  init(selfEquivalent: TokenSyntax) {
    self.selfEquivalent = selfEquivalent
  }

  override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
    guard node.name.text == "Self"
    else { return super.visit(node) }
    return super.visit(node.with(\.name, self.selfEquivalent))
  }
}

final class ElementRewriter: SyntaxRewriter {
  var didRewriteElement = false

  override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
    guard node.name.text == "Element"
    else { return super.visit(node) }
    didRewriteElement = true
    return super.visit(node.with(\.name, "_$Element"))
  }
}

extension [String] {
  fileprivate var qualified: [String] {
    map(\.qualified)
  }
}

extension String {
  fileprivate var qualified: String {
    "\(CasePathableMacro.moduleName).\(self)"
  }
}

extension StringProtocol {
  @inline(__always)
  func trimmingSuffix(while condition: (Element) throws -> Bool) rethrows -> Self.SubSequence {
    var view = self[...]

    while let character = view.last, try condition(character) {
      view = view.dropLast()
    }

    return view
  }
}
