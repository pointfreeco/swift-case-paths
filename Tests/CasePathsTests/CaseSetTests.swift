#if swift(>=6)
  import CasePaths
  import Testing

  @dynamicMemberLookup
  public struct CaseSet<Root: CasePathable>: Sequence {
    private var storage: [PartialCaseKeyPath<Root> & Sendable: Root] = [:]

    public init() {}

    public init(_ elements: some Collection<Root>)
    where Root.AllCasePaths: CasePathReflectable<Root> {
      self.storage = [PartialCaseKeyPath<Root> & Sendable: Root](
        uniqueKeysWithValues: elements.map { (Root.allCasePaths[$0], $0) }
      )
    }

    public subscript<Member>(
      dynamicMember keyPath: CaseKeyPath<Root, Member> & Sendable
    ) -> Member? {
      get { storage[keyPath].flatMap { $0[case: keyPath] } }
      set { storage[keyPath] = newValue.map(keyPath.callAsFunction) }
    }

    public subscript(
      dynamicMember keyPath: CaseKeyPath<Root, Void> & Sendable
    ) -> Bool {
      get { storage[keyPath].flatMap { $0[case: keyPath] } != nil }
      set { storage[keyPath] = newValue ? keyPath() : nil }
    }

    public func makeIterator() -> some IteratorProtocol<Root> {
      storage.values.makeIterator()
    }
  }

  extension CaseSet: Equatable where Root: Equatable {}
  extension CaseSet: Hashable where Root: Hashable {}
  extension CaseSet: Sendable where Root: Sendable {}

  extension CaseSet: ExpressibleByArrayLiteral where Root.AllCasePaths: CasePathReflectable<Root> {
    public init(arrayLiteral elements: Root...) {
      self.init(elements)
    }
  }

  @CasePathable private enum Post {
    case title(String)
    case body(String)
    case isHidden
  }

  @Test private func caseSet() {
    var set: CaseSet<Post> = [.title("Hello")]
    set.body = "World"
    set.isHidden = true

    #expect(set.title == "Hello")
    #expect(set.body == "World")
    #expect(set.isHidden)
  }
#endif
