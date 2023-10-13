// TODO: Do we want this instead of `enum.is(\.case)`

extension CasePathable {
  /// Returns a case predicate for this enum.
  ///
  /// Useful for testing if an enum matches a case:
  ///
  /// ```swift
  /// @CasePathable
  /// enum UserAction {
  ///   case home(HomeAction)
  ///   case settings(SettingsAction)
  /// }
  ///
  /// let userAction: UserAction = .home(.onAppear)
  /// userAction.is.home      // true
  /// userAction.is.settings  // false
  ///
  /// let userActions: [UserAction] = [.home(.onAppear), .settings(.subscribeButtonTapped)]
  /// userActions.filter(\.is.home)      // [UserAction.home(.onAppear)]
  /// userActions.filter(\.is.settings)  // [UserAction.settings(.subscribeButtonTapped)]
  /// ```
  public var `is`: CasePredicate<Self> {
    CasePredicate(wrappedValue: self)
  }
}

@dynamicMemberLookup
public struct CasePredicate<Root: CasePathable> {
  private let wrappedValue: Root?

  fileprivate init(wrappedValue: Root?) {
    self.wrappedValue = wrappedValue
  }

  @_disfavoredOverload
  public subscript<Value>(dynamicMember keyPath: CaseKeyPath<Root, Value>) -> Bool {
    self.wrappedValue?[keyPath: keyPath] != nil
  }

  public subscript<Value>(dynamicMember keyPath: CaseKeyPath<Root, Value>) -> CasePredicate<Value> {
    CasePredicate<Value>(wrappedValue: self.wrappedValue?[keyPath: keyPath])
  }

  public func callAsFunction() -> Bool {
    self.wrappedValue != nil
  }
}
