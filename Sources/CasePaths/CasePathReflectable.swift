/// An identity case path that can also reflect the case path of a given root value.
///
/// The `@CasePathable` macro automatically generates a conformance to this protocol on the enum's
/// ``CasePathable/AllCasePaths`` type.
///
/// You can look up an enum's case path by passing it to ``CasePathReflectable/subscript(_:)``:
///
/// ```swift
/// @CasePathable
/// enum Field {
///   case title(String)
///   case body(String)
///   case isLive
/// }
///
/// Field.allCasePaths[.title("Hello, Blob!")]  // \.title
/// ```
public protocol CasePathReflectable<Root>: CasePath, Sequence
where Root == Value, Element == PartialKeyPath<Self> {
  /// Returns the case key path for a given root value.
  ///
  /// - Parameter root: A root value.
  /// - Returns: A case path to the root value.
  subscript(root: Root) -> PartialKeyPath<Self> { get }
}
