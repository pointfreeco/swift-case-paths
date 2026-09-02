/// A type that can reflect the case paths of an enum.
///
/// The `@CasePathable` macro automatically generates a conformance to this protocol on the enum's
/// ``CasePathable/AllCasePaths`` type, which powers ``CasePathable/case`` and iteration over an
/// enum's case key paths:
///
/// ```swift
/// @CasePathable
/// enum Field {
///   case title(String)
///   case body(String)
///   case isLive
/// }
///
/// Field.title("Hello, Blob!").case  // \.title
/// Array(Field.allCasePaths)         // [\.title, \.body, \.isLive]
/// ```
///
/// You should not need to interact with this protocol directly. Constrain generic code to
/// ``CasePathable`` instead.
public protocol CasePathReflectable<Root> {
  /// The enum type that can be reflected.
  associatedtype Root: CasePathable

  static func _case(for root: Root) -> PartialCaseKeyPath<Root>

  static var _allCaseKeyPaths: [PartialCaseKeyPath<Root>] { get }

  /// Returns the case key path for a given root value.
  ///
  /// - Parameter root: A root value.
  /// - Returns: A case path to the root value.
  @available(*, deprecated, message: "Use 'root.case' instead")
  subscript(root: Root) -> PartialCaseKeyPath<Root> { get }
}

extension CasePathReflectable {
  @available(*, deprecated, message: "Use 'root.case' instead")
  public subscript(root: Root) -> PartialCaseKeyPath<Root> {
    root.case
  }
}

extension CasePathReflectable where Root.AllCasePaths == Self {
  @available(*, deprecated, message: "Implement 'static _case(for:)' instead")
  public static func _case(for root: Root) -> PartialCaseKeyPath<Root> {
    Root.allCasePaths[root]
  }
}

extension CasePathReflectable {
  @available(*, deprecated, message: "Implement 'static _allCaseKeyPaths' instead")
  public static var _allCaseKeyPaths: [PartialCaseKeyPath<Root>] {
    []
  }
}

extension CasePathReflectable
where Self: Sequence, Element == PartialCaseKeyPath<Root>, Root.AllCasePaths == Self {
  @available(*, deprecated, message: "Implement 'static _allCaseKeyPaths' instead")
  public static var _allCaseKeyPaths: [PartialCaseKeyPath<Root>] {
    Array(Root.allCasePaths)
  }
}

extension CasePathReflectable where Self: Sequence, Element == PartialCaseKeyPath<Root> {
  @available(*, deprecated, message: "Iterate over 'Array(Enum.allCasePaths)' instead")
  public func makeIterator() -> IndexingIterator<[PartialCaseKeyPath<Root>]> {
    Self._allCaseKeyPaths.makeIterator()
  }
}
