/// A type that provides a collection of all of its case paths.
///
/// The `@CasePathable` macro automatically generates a conformance to this protocol.
///
/// You can iterate over ``CasePathable/allCasePaths`` to get access to each individual case path:
///
/// ```swift
/// @CasePathable enum Field {
///   case title(String)
///   case body(String
///   case isLive
/// }
///
/// Array(Field.allCasePaths)  // [\.title, \.body, \.isLive]
/// ```
public protocol CasePathIterable: CasePathable
where AllCasePaths: Sequence, AllCasePaths.Element == PartialCaseKeyPath<Self> {}
