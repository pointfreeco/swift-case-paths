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



//@CasePathable
private enum ExtractAction {
  case extract
  public struct AllCasePaths: CasePaths.CasePathReflectable, Swift.Sendable, Swift.Sequence {
    public subscript(root: ExtractAction) -> CasePaths.PartialCaseKeyPath<ExtractAction> {
      if root.is(\.extract) {
        return \.extract
      }
      return \.never
    }
    public var extract: CasePaths.AnyCasePath<ExtractAction, Void> {
      ._$embed({
        ExtractAction.extract
      }) {
        guard case .extract = $0 else {
          return nil
        }
        return ()
      }
    }
    public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<ExtractAction>]> {
      var allCasePaths: [CasePaths.PartialCaseKeyPath<ExtractAction>] = []
      allCasePaths.append(\.extract)
      return allCasePaths.makeIterator()
    }
  }
  public static var allCasePaths: AllCasePaths { AllCasePaths() }
}
extension ExtractAction: CasePaths.CasePathable, CasePaths.CasePathIterable {
}
