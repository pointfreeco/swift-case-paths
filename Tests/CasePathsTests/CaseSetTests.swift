#if canImport(Testing) && swift(>=6)
  public import CasePaths
  import Testing

  @dynamicMemberLookup
  public struct CaseSet<Element: CasePathable> {
    private var storage: [PartialCaseKeyPath<Element>: Element] = [:]

    public init() {}

    public init(_ elements: some Collection<Element>) {
      self.storage = [PartialCaseKeyPath<Element> & Sendable: Element](
        uniqueKeysWithValues: elements.map { (Element.allCasePaths[$0], $0) }
      )
    }

    public subscript<Path>(
      dynamicMember keyPath: CaseKeyPath<Element, Path>
    ) -> Path.Value? {
      get { storage[keyPath].flatMap { $0[case: keyPath] } }
      set { storage[keyPath] = newValue.map { keyPath($0) } }
    }

    public subscript<Path>(
      dynamicMember keyPath: CaseKeyPath<Element, Path>
    ) -> Bool where Path.Value == Void {
      get { storage[keyPath].flatMap { $0[case: keyPath] } != nil }
      set { storage[keyPath] = newValue ? keyPath() : nil }
    }
  }

  extension CaseSet: Collection {
    public struct Index: Comparable {
      fileprivate let rawValue: [PartialCaseKeyPath<Element>: Element].Index

      public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
      }
    }

    public var startIndex: Index { Index(rawValue: storage.startIndex) }
    public var endIndex: Index { Index(rawValue: storage.endIndex) }
    public func index(after i: Index) -> Index { Index(rawValue: storage.index(after: i.rawValue)) }
    public subscript(position: Index) -> Element { storage[position.rawValue].value }
  }

  extension CaseSet: SetAlgebra where Element: Equatable {
    public var isEmpty: Bool { storage.isEmpty }

    public func union(_ other: CaseSet<Element>) -> CaseSet<Element> {
      var copy = self
      copy.formUnion(other)
      return copy
    }

    public func intersection(_ other: CaseSet<Element>) -> CaseSet<Element> {
      var copy = self
      copy.formIntersection(other)
      return copy
    }

    public func symmetricDifference(_ other: CaseSet<Element>) -> CaseSet<Element> {
      var copy = self
      copy.formSymmetricDifference(other)
      return copy
    }

    @discardableResult
    public mutating func insert(
      _ newMember: Element
    ) -> (inserted: Bool, memberAfterInsert: Element) {
      let inserted = storage.updateValue(newMember, forKey: Element.allCasePaths[newMember]) == nil
      return (inserted, newMember)
    }

    @discardableResult
    public mutating func remove(_ member: Element) -> Element? {
      storage.removeValue(forKey: Element.allCasePaths[member])
    }

    @discardableResult
    public mutating func update(with newMember: Element) -> Element? {
      let inserted = storage.updateValue(newMember, forKey: Element.allCasePaths[newMember]) == nil
      return inserted ? nil : newMember
    }

    public mutating func formUnion(_ other: CaseSet<Element>) {
      storage.merge(other.storage, uniquingKeysWith: { $1 })
    }

    public mutating func formIntersection(_ other: CaseSet<Element>) {
      for keyPath in other.storage.keys {
        if !storage.keys.contains(keyPath) {
          storage.removeValue(forKey: keyPath)
        }
      }
    }

    public mutating func formSymmetricDifference(_ other: CaseSet<Element>) {
      for (keyPath, value) in other.storage {
        if storage.keys.contains(keyPath) {
          storage.removeValue(forKey: keyPath)
        } else {
          storage[keyPath] = value
        }
      }
    }
  }

  extension CaseSet: Equatable where Element: Equatable {}
  extension CaseSet: Hashable where Element: Hashable {}
  extension CaseSet: @unchecked Sendable where Element: Sendable {}

  extension CaseSet: Decodable where Element: Decodable {
    public init(from decoder: any Decoder) throws {
      var container = try decoder.unkeyedContainer()
      if let count = container.count {
        storage.reserveCapacity(count)
      }
      while !container.isAtEnd {
        let element = try container.decode(Element.self)
        if let original = storage.updateValue(element, forKey: Element.allCasePaths[element]) {
          throw DecodingError.dataCorrupted(
            DecodingError.Context(
              codingPath: container.codingPath,
              debugDescription: "Duplicate elements for case: '\(original)', '\(element)'"
            )
          )
        }
      }
    }
  }

  extension CaseSet: Encodable where Element: Encodable {
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.unkeyedContainer()
      for element in storage.values {
        try container.encode(element)
      }
    }
  }

  extension CaseSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
      self.init(elements)
    }
  }

  extension CaseSet {
    @_disfavoredOverload
    public subscript<Path>(
      dynamicMember keyPath: CaseKeyPath<Element, Path>
    ) -> CaseSetBuilder<Element, Path> {
      CaseSetBuilder(set: self, keyPath: keyPath)
    }
  }

  public struct CaseSetBuilder<Root: CasePathable, Path: CasePath> where Path.Root == Root {
    let set: CaseSet<Root>
    let keyPath: CaseKeyPath<Root, Path>

    public func callAsFunction(_ value: Path.Value?) -> CaseSet<Root> {
      var set = set
      set[dynamicMember: keyPath] = value
      return set
    }

    public func callAsFunction(_ value: Bool = true) -> CaseSet<Root> where Path.Value == Void {
      var set = set
      set[dynamicMember: keyPath] = value ? () : nil
      return set
    }
  }

  extension CaseSet {
    // NB: Parameter packs cannot yet express '(each Path).Root == Element', so this spells
    // the key path type out rather than using the constrained 'CaseKeyPath' alias.
    public func require<each Path: CasePath>(
      _ keyPath: repeat KeyPath<Element.AllCasePaths, each Path> & Sendable
    ) -> (repeat (each Path).Value)? {
      func value<P: CasePath>(at keyPath: KeyPath<Element.AllCasePaths, P>) throws -> P.Value {
        guard
          let element = storage[keyPath],
          let value = element[case: keyPath as PartialCaseKeyPath<Element>] as? P.Value
        else { throw Nil() }
        return value
      }
      return try? (repeat value(at: each keyPath))
    }

    private struct Nil: Error {}
  }

  @CasePathable private enum Post: Equatable {
    case title(String)
    case body(String)
    case isHidden
  }

  @Test private func caseSet() throws {
    var set: CaseSet<Post> = [.title("Hello")]
    set.body = "World"
    set.isHidden = true

    #expect(set.title == "Hello")
    #expect(set.body == "World")
    #expect(set.isHidden)

    let newSet = set.title("Goodnight")
      .body("Moon")
      .isHidden(false)

    #expect(newSet == [.title("Goodnight"), .body("Moon")])

    #expect(newSet.title(nil).body(nil).isEmpty)

    let required = try #require(newSet.require(\.title, \.body))
    #expect(required == ("Goodnight", "Moon"))

    #expect(newSet.require(\.title, \.isHidden) == nil)
  }
#endif
