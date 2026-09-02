/// A type that provides a collection of all of its case paths.
///
/// The `@CasePathable` macro automatically generates a conformance to this protocol.
///
/// You can collect ``CasePathable/allCasePaths`` into an array to get access to each case path:
///
/// ```swift
/// @CasePathable enum Field {
///   case title(String)
///   case body(String)
///   case isLive
/// }
///
/// Array(Field.allCasePaths)  // [\.title, \.body, \.isLive]
/// ```
public protocol CasePathIterable: CasePathable
where AllCasePaths: Sequence, AllCasePaths.Element == PartialCaseKeyPath<Self> {}
