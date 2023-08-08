public protocol CasePathable {
  associatedtype AllCasePaths // : CasePathIterable<Self>
  static var allCasePaths: AllCasePaths { get }
}

extension CasePath where Root: CasePathable {
  public static func _$case(_ keyPath: KeyPath<Root.AllCasePaths, Self>) -> Self {
    Root.allCasePaths[keyPath: keyPath]
  }
}

extension CasePath where Root: CasePathable, Root == Value {
  public static func _$case(_ keyPath: KeyPath<Root.AllCasePaths, Root.AllCasePaths>) -> Self {
    CasePath(
      embed: { $0 },
      extract: { $0 },
      keyPaths: []
    )
  }
}

//public protocol CasePathIterable<Root>: Collection {
//  associatedtype Root: CasePathable
//  associatedtype Element = any PartialCasePath<Root>
//  associatedtype Index = Int
//  var _$elements: [any PartialCasePath<Root>] { get }
//  // TODO: Use ordered dictionary for lookup?
//  // var _$elements: OrderedDictionary<PartialKeyPath<Root>, any PartialCasePath<Root>> { get }
//}
//
//extension CasePathIterable {
//  public var startIndex: Int { self._$elements.startIndex }
//  public var endIndex: Int { self._$elements.endIndex }
//  public func index(after i: Int) -> Int { self._$elements.index(after: i) }
//  public subscript(position: Int) -> any PartialCasePath<Root> { self._$elements[position] }
//}
