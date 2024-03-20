extension Never: CasePathable {
  public struct AllCasePaths {}
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }
}

extension Case where Value: CasePathable {
  /// A case path that can never embed or extract a value.
  ///
  /// This property can chain any case path into a `Never` value, which, as an uninhabited type,
  /// cannot be embedded nor extracted from an enum.
  public var never: Case<Never> {
    func absurd<T>(_: Never) -> T {}
    return Case<Never>(embed: absurd, extract: { (_: Value) in nil })
  }
}

#if DEBUG, swift(>=5.9)
  extension Case {
    /// ⚠️ The current enum is not `@CasePathable` and cannot derive key paths into its cases. Mark
    /// this enum `@CasePathable`, or extend it with a manual `CasePathable` conformance to enable
    /// case key path syntax.
    ///
    /// A case path that can never embed or extract a value.
    ///
    /// This property can chain any case path into a `Never` value, which, as an uninhabited type,
    /// cannot be embedded nor extracted from an enum.
    @_documentation(visibility: private)
    public var never: Case<Never> {
      func absurd<T>(_: Never) -> T {}
      return Case<Never>(embed: absurd, extract: { (_: Value) in nil })
    }
  }
#endif
