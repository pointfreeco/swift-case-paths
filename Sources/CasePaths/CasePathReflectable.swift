/// A type that can reflect a case path from a given case.
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
public protocol CasePathReflectable<Root> {
  /// The enum type that can be reflected.
  associatedtype Root: CasePathable

  /// Returns the case key path for a given root value.
  ///
  /// - Parameter root: An root value.
  /// - Returns: A case path to the root value.
  subscript(root: Root) -> PartialCaseKeyPath<Root> { get }
}
