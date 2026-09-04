extension RangeReplaceableCollection {
  /// Creates a collection of all the case key paths in a case-pathable enum.
  ///
  /// ```swift
  /// Array(Field.allCasePaths)  // [\.title, \.body, \.isLive]
  /// ```
  ///
  /// - Parameter allCasePaths: An enum's collection of case key paths.
  @inlinable
  public init<R: CasePath>(_ allCasePaths: R)
  where R.Root: CasePathable, R.Root.AllCasePaths == R, Element == PartialKeyPath<R> {
    self.init(R.Root._allCaseKeyPaths)
  }
}

extension Set {
  /// Creates a set of all the case key paths in a case-pathable enum.
  ///
  /// ```swift
  /// Set(Field.allCasePaths)  // [\.title, \.body, \.isLive]
  /// ```
  ///
  /// - Parameter allCasePaths: An enum's collection of case key paths.
  @inlinable
  public init<R: CasePath>(_ allCasePaths: R)
  where R.Root: CasePathable, R.Root.AllCasePaths == R, Element == PartialKeyPath<R> {
    self.init(R.Root._allCaseKeyPaths)
  }
}
