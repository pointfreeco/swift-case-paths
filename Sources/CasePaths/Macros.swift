/// Defines and implements conformance of the CasePathable protocol.
///
/// This macro conforms the type to the `CasePathable` protocol, and adds `CaseKeyPath` support for
/// all its cases.
///
/// For example, the following code applies the `CasePathable` macro to the type `UserAction`:
///
/// ```swift
/// @CasePathable
/// enum UserAction {
///   case home(HomeAction)
///   case settings(SettingsAction)
/// }
/// ```
///
/// This macro application extends the type with the ability to derive case key paths from each
/// of its cases using a familiar key path expression:
///
/// ```swift
/// // Case key paths can be inferred using the same name as the case:
/// _: CaseKeyPath<UserAction, HomeAction> = \.home
/// _: CaseKeyPath<UserAction, SettingsAction> = \.settings
///
/// // Or they can be fully qualified under the type's `Cases`:
/// \UserAction.Cases.home      // CasePath<UserAction, HomeAction>
/// \UserAction.Cases.settings  // CasePath<UserAction, SettingsAction>
/// ```
@attached(extension, conformances: CasePathable, CasePathIterable)
@attached(member, names: named(AllCasePaths), named(allCasePaths), named(_$Element))
public macro CasePathable() =
  #externalMacro(
    module: "CasePathsMacros", type: "CasePathableMacro"
  )
