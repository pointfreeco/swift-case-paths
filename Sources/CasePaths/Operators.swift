prefix operator /

extension AnyCasePath {
  #if swift(>=5.9)
    @available(iOS, deprecated: 9999)
    @available(macOS, deprecated: 9999)
    @available(tvOS, deprecated: 9999)
    @available(watchOS, deprecated: 9999)
    public static func ~= (pattern: AnyCasePath, value: Root) -> Bool {
      pattern.extract(from: value) != nil
    }
  #else
    /// Returns whether or not a root value matches a particular case path.
    ///
    /// ```swift
    /// [Result<Int, Error>.success(1), .success(2), .failure(NSError()), .success(4)]
    ///   .prefix(while: { /Result.success ~= $0 })
    /// // [.success(1), .success(2)]
    /// ```
    ///
    /// - Parameters:
    ///   - pattern: A case path.
    ///   - value: A root value.
    /// - Returns: Whether or not a root value matches a particular case path
    public static func ~= (pattern: AnyCasePath, value: Root) -> Bool {
      pattern.extract(from: value) != nil
    }
  #endif
}

#if swift(>=5.9)
  @available(iOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(macOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(tvOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(watchOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @_documentation(visibility:internal)
  public prefix func / <Root, Value>(
    embed: @escaping (Value) -> Root
  ) -> AnyCasePath<Root, Value> {
    .init(embed: embed, extract: extractHelp(embed))
  }
#else
  /// Returns a case path for the given embed function.
  ///
  /// - Note: This operator is only intended to be used with enum case initializers. Its behavior is
  ///   otherwise undefined.
  /// - Parameter embed: An embed function.
  /// - Returns: A case path.
  public prefix func / <Root, Value>(
    embed: @escaping (Value) -> Root
  ) -> AnyCasePath<Root, Value> {
    .init(embed: embed, extract: extractHelp(embed))
  }
#endif

#if swift(>=5.9)
  @available(iOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(macOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(tvOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(watchOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @_documentation(visibility:internal)
  public prefix func / <Root, Value>(
    embed: @escaping (Value) -> Root?
  ) -> AnyCasePath<Root?, Value> {
    .init(embed: embed, extract: optionalPromotedExtractHelp(embed))
  }
#else
  /// Returns a case path for the given embed function.
  ///
  /// - Note: This operator is only intended to be used with enum case initializers. Its behavior is
  ///   otherwise undefined.
  /// - Parameter embed: An embed function.
  /// - Returns: A case path.
  public prefix func / <Root, Value>(
    embed: @escaping (Value) -> Root?
  ) -> AnyCasePath<Root?, Value> {
    .init(embed: embed, extract: optionalPromotedExtractHelp(embed))
  }
#endif

#if swift(>=5.9)
  @available(iOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(macOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(tvOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(watchOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @_documentation(visibility:internal)
  public prefix func / <Root>(
    root: Root
  ) -> AnyCasePath<Root, Void> {
    .init(embed: { root }, extract: extractVoidHelp(root))
  }
#else
  /// Returns a void case path for a case with no associated value.
  ///
  /// - Note: This operator is only intended to be used with enum cases that have no associated
  ///   values. Its behavior is otherwise undefined.
  /// - Parameter root: A case with no an associated value.
  /// - Returns: A void case path.
  public prefix func / <Root>(
    root: Root
  ) -> AnyCasePath<Root, Void> {
    .init(embed: { root }, extract: extractVoidHelp(root))
  }
#endif

#if swift(>=5.9)
  @available(iOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(macOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(tvOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @available(watchOS, deprecated: 9999, message: "Use a 'CasePathable' case key path, instead")
  @_documentation(visibility:internal)
  public prefix func / <Root>(
    root: Root?
  ) -> AnyCasePath<Root?, Void> {
    .init(embed: { root }, extract: optionalPromotedExtractVoidHelp(root))
  }
#else
  /// Returns a void case path for a case with no associated value.
  ///
  /// - Note: This operator is only intended to be used with enum cases that have no associated
  ///   values. Its behavior is otherwise undefined.
  /// - Parameter root: A case with no an associated value.
  /// - Returns: A void case path.
  public prefix func / <Root>(
    root: Root?
  ) -> AnyCasePath<Root?, Void> {
    .init(embed: { root }, extract: optionalPromotedExtractVoidHelp(root))
  }
#endif

#if swift(>=5.9)
  @available(iOS, deprecated: 9999, message: "Use the '\\.self' case key path, instead")
  @available(macOS, deprecated: 9999, message: "Use the '\\.self' case key path, instead")
  @available(tvOS, deprecated: 9999, message: "Use the '\\.self' case key path, instead")
  @available(watchOS, deprecated: 9999, message: "Use the '\\.self' case key path, instead")
  @_documentation(visibility:internal)
  public prefix func / <Root>(
    type: Root.Type
  ) -> AnyCasePath<Root, Root> {
    .self
  }
#else
  /// Returns the identity case path for the given type. Enables `/MyType.self` syntax.
  ///
  /// - Parameter type: A type for which to return the identity case path.
  /// - Returns: An identity case path.
  public prefix func / <Root>(
    type: Root.Type
  ) -> AnyCasePath<Root, Root> {
    .self
  }
#endif

#if swift(>=5.9)
  @available(
    iOS, deprecated: 9999, message: "Use the a case key path (like '\\.self' or '\\.some'), instead"
  )
  @available(
    macOS, deprecated: 9999,
    message: "Use the a case key path (like '\\.self' or '\\.some'), instead"
  )
  @available(
    tvOS, deprecated: 9999,
    message: "Use the a case key path (like '\\.self' or '\\.some'), instead"
  )
  @available(
    watchOS, deprecated: 9999,
    message: "Use the a case key path (like '\\.self' or '\\.some'), instead"
  )
  @_documentation(visibility:internal)
  public prefix func / <Root, Value>(
    path: AnyCasePath<Root, Value>
  ) -> AnyCasePath<Root, Value> {
    path
  }
#else
  /// Identifies and returns a given case path. Enables shorthand syntax on static case paths,
  /// _e.g._ `/.self`  instead of `.self`, and `/.some` instead of `.some`.
  ///
  /// - Parameter path: A case path to return.
  /// - Returns: The case path.
  public prefix func / <Root, Value>(
    path: AnyCasePath<Root, Value>
  ) -> AnyCasePath<Root, Value> {
    path
  }
#endif

#if swift(>=5.9)
  @available(
    iOS, deprecated: 9999,
    message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
  )
  @available(
    macOS, deprecated: 9999,
    message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
  )
  @available(
    tvOS, deprecated: 9999,
    message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
  )
  @available(
    watchOS, deprecated: 9999,
    message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
  )
  @_disfavoredOverload
  @_documentation(visibility:internal)
  public prefix func / <Root, Value>(
    embed: @escaping (Value) -> Root
  ) -> (Root) -> Value? {
    (/embed).extract(from:)
  }
#else
  /// Returns a function that can attempt to extract associated values from the given enum case
  /// initializer.
  ///
  /// Use this operator to create new transform functions to pass to higher-order methods like
  /// `compactMap`:
  ///
  /// ```swift
  /// [Result<Int, Error>.success(42), .failure(MyError()]
  ///   .compactMap(/Result.success)
  /// // [42]
  /// ```
  ///
  /// - Note: This operator is only intended to be used with enum case initializers. Its behavior is
  ///   otherwise undefined.
  /// - Parameter embed: An enum case initializer.
  /// - Returns: A function that can attempt to extract associated values from an enum.
  @_disfavoredOverload
  public prefix func / <Root, Value>(
    embed: @escaping (Value) -> Root
  ) -> (Root) -> Value? {
    (/embed).extract(from:)
  }
#endif

#if swift(>=5.9)
  @available(iOS, deprecated: 9999, message: "Use a 'CasePathable' case property, instead")
  @available(macOS, deprecated: 9999, message: "Use a 'CasePathable' case property, instead")
  @available(tvOS, deprecated: 9999, message: "Use a 'CasePathable' case property, instead")
  @available(watchOS, deprecated: 9999, message: "Use a 'CasePathable' case property, instead")
  @_disfavoredOverload
  @_documentation(visibility:internal)
  public prefix func / <Root, Value>(
    embed: @escaping (Value) -> Root?
  ) -> (Root?) -> Value? {
    (/embed).extract(from:)
  }
#else
  /// Returns a function that can attempt to extract associated values from the given enum case
  /// initializer.
  ///
  /// Use this operator to create new transform functions to pass to higher-order methods like
  /// `compactMap`:
  ///
  /// ```swift
  /// [Result<Int, Error>.success(42), .failure(MyError()]
  ///   .compactMap(/Result.success)
  /// // [42]
  /// ```
  ///
  /// - Note: This operator is only intended to be used with enum case initializers. Its behavior is
  ///   otherwise undefined.
  /// - Parameter embed: An enum case initializer.
  /// - Returns: A function that can attempt to extract associated values from an enum.
  @_disfavoredOverload
  public prefix func / <Root, Value>(
    embed: @escaping (Value) -> Root?
  ) -> (Root?) -> Value? {
    (/embed).extract(from:)
  }
#endif

#if swift(>=5.9)
  @available(
    iOS, deprecated: 9999,
    message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
  )
  @available(
    macOS, deprecated: 9999,
    message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
  )
  @available(
    tvOS, deprecated: 9999,
    message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
  )
  @available(
    watchOS, deprecated: 9999,
    message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
  )
  @_disfavoredOverload
  @_documentation(visibility:internal)
  public prefix func / <Root>(
    root: Root
  ) -> (Root) -> Void? {
    (/root).extract(from:)
  }
#else
  /// Returns a void case path for a case with no associated value.
  ///
  /// - Note: This operator is only intended to be used with enum cases that have no associated
  ///   values. Its behavior is otherwise undefined.
  /// - Parameter root: A case with no an associated value.
  /// - Returns: A void case path.
  @_disfavoredOverload
  public prefix func / <Root>(
    root: Root
  ) -> (Root) -> Void? {
    (/root).extract(from:)
  }
#endif

#if swift(>=5.9)
  @available(
    iOS, deprecated: 9999,
    message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
  )
  @available(
    macOS, deprecated: 9999,
    message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
  )
  @available(
    tvOS, deprecated: 9999,
    message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
  )
  @available(
    watchOS, deprecated: 9999,
    message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
  )
  @_disfavoredOverload
  @_documentation(visibility:internal)
  public prefix func / <Root>(
    root: Root
  ) -> (Root?) -> Void? {
    (/root).extract(from:)
  }
#else
  /// Returns a void case path for a case with no associated value.
  ///
  /// - Note: This operator is only intended to be used with enum cases that have no associated
  ///   values. Its behavior is otherwise undefined.
  /// - Parameter root: A case with no an associated value.
  /// - Returns: A void case path.
  @_disfavoredOverload
  public prefix func / <Root>(
    root: Root
  ) -> (Root?) -> Void? {
    (/root).extract(from:)
  }
#endif

precedencegroup CasePathCompositionPrecedence {
  associativity: left
}

infix operator .. : CasePathCompositionPrecedence

extension AnyCasePath {
  #if swift(>=5.9)
    @available(iOS, deprecated: 9999, message: "Append 'CasePathable' case key paths, instead")
    @available(macOS, deprecated: 9999, message: "Append 'CasePathable' case key paths, instead")
    @available(tvOS, deprecated: 9999, message: "Append 'CasePathable' case key paths, instead")
    @available(watchOS, deprecated: 9999, message: "Append 'CasePathable' case key paths, instead")
    public static func .. <AppendedValue>(
      lhs: AnyCasePath,
      rhs: AnyCasePath<Value, AppendedValue>
    ) -> AnyCasePath<Root, AppendedValue> {
      lhs.appending(path: rhs)
    }
  #else
    /// Returns a new case path created by appending the given case path to this one.
    ///
    /// The operator version of ``appending(path:)``. Use this method to extend this case path to
    /// the value type of another case path.
    ///
    /// - Parameters:
    ///   - lhs: A case path from a root to a value.
    ///   - rhs: A case path from the first case path's value to some other appended value.
    /// - Returns: A new case path from the first case path's root to the second case path's value.
    public static func .. <AppendedValue>(
      lhs: AnyCasePath,
      rhs: AnyCasePath<Value, AppendedValue>
    ) -> AnyCasePath<Root, AppendedValue> {
      lhs.appending(path: rhs)
    }
  #endif

  #if swift(>=5.9)
    @available(iOS, deprecated: 9999, message: "Append 'CasePathable' case key paths, instead")
    @available(macOS, deprecated: 9999, message: "Append 'CasePathable' case key paths, instead")
    @available(tvOS, deprecated: 9999, message: "Append 'CasePathable' case key paths, instead")
    @available(watchOS, deprecated: 9999, message: "Append 'CasePathable' case key paths, instead")
    public static func .. <AppendedValue>(
      lhs: AnyCasePath,
      rhs: @escaping (AppendedValue) -> Value
    ) -> AnyCasePath<Root, AppendedValue> {
      lhs.appending(path: /rhs)
    }
  #else
    /// Returns a new case path created by appending the given embed function.
    ///
    /// - Parameters:
    ///   - lhs: A case path from a root to a value.
    ///   - rhs: An embed function from an appended value.
    /// - Returns: A new case path from the first case path's root to the second embed function's
    ///   value.
    public static func .. <AppendedValue>(
      lhs: AnyCasePath,
      rhs: @escaping (AppendedValue) -> Value
    ) -> AnyCasePath<Root, AppendedValue> {
      lhs.appending(path: /rhs)
    }
  #endif
}

#if swift(>=5.9)
  @available(iOS, deprecated: 9999, message: "Chain 'CasePathable' case properties, instead")
  @available(macOS, deprecated: 9999, message: "Chain 'CasePathable' case properties, instead")
  @available(tvOS, deprecated: 9999, message: "Chain 'CasePathable' case properties, instead")
  @available(watchOS, deprecated: 9999, message: "Chain 'CasePathable' case properties, instead")
  public func .. <Root, Value, AppendedValue>(
    lhs: @escaping (Root) -> Value?,
    rhs: @escaping (AppendedValue) -> Value
  ) -> (Root) -> AppendedValue? {
    return { root in lhs(root).flatMap((/rhs).extract(from:)) }
  }
#else
  /// Returns a new extract function by appending the given extract function with an embed function.
  ///
  /// Useful when composing extract functions together.
  ///
  /// ```swift
  /// [Result<Int?, Error>.success(.some(42)), .success(nil), .failure(MyError())]
  ///   .compactMap(/Result.success..Optional.some)
  /// // [42]
  /// ```
  ///
  /// - Parameters:
  ///   - lhs: An extract function from a root to a value.
  ///   - rhs: An embed function from some other appended value to the extract function's value.
  /// - Returns: A new extract function from the first extract function's root to the second embed
  ///   function's appended value.
  public func .. <Root, Value, AppendedValue>(
    lhs: @escaping (Root) -> Value?,
    rhs: @escaping (AppendedValue) -> Value
  ) -> (Root) -> AppendedValue? {
    return { root in lhs(root).flatMap((/rhs).extract(from:)) }
  }
#endif
