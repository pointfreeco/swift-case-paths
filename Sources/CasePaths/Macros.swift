/// Defines and implements conformance of the CasePathable protocol
///
/// This macro adds ``CasePath`` support to a custom type and conforms the type to the
/// `CasePathable` protocol. For example, the following code applies the `CasePathable` macro to the
/// type `UserAction`:
///
/// ```swift
/// @CasePathable
/// enum UserAction {
///   case home(HomeAction)
///   case settings(SettingsAction)
/// }
/// ```
///
/// This macro application extends the type with the ability to produce case paths to each of its
/// cases using the ``casePath(_:)-4n3fo`` macro.
@attached(extension, conformances: CasePathable)
@attached(member, names: arbitrary)
public macro CasePathable() = #externalMacro(module: "CasePathsMacros", type: "CasePathableMacro")

/// Produces a case path for a given "case-pathable" key path.
@freestanding(expression)
public macro casePath<Root: CasePathable, Value>(
  _ keyPath: KeyPath<Root, Value?>
) -> CasePath<Root, Value> = #externalMacro(module: "CasePathsMacros", type: "CasePathMacro")

/// Produces an identity case path for a given "case-pathable" identity key path.
///
/// The identity case path is a case path that:
///
///   * Given a value to embed, returns the given value.
///   * Given a value to extract, returns the given value.
///
/// For example:
///
/// ```swift
/// #casePath(\.self)
/// ```
@freestanding(expression)
public macro casePath<Root: CasePathable>(
  _ keyPath: KeyPath<Root, Root>
) -> CasePath<Root, Root> = #externalMacro(module: "CasePathsMacros", type: "CasePathMacro")
