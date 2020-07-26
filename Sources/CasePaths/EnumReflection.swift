import func Foundation.memcmp

extension CasePath {
  /// Returns a case path that extracts values associated with a given enum case initializer.
  ///
  /// - Note: This function is only intended to be used with enum case initializers. Its behavior is
  ///   otherwise undefined.
  /// - Parameter embed: An enum case initializer.
  /// - Returns: A case path that extracts associated values from enum cases.
  public static func `case`(_ embed: @escaping (Value) -> Root) -> CasePath {
    return self.init(
      embed: embed,
      extract: { CasePaths.extract(case: embed, from: $0) }
    )
  }
}

extension CasePath where Value == Void {
  /// Returns a case path that successfully extracts `()` from a given enum case with no associated
  /// values.
  ///
  /// - Note: This function is only intended to be used with enum cases that have no associated
  ///   values. Its behavior is otherwise undefined.
  /// - Parameter value: An enum case with no associated values.
  /// - Returns: A case path that extracts `()` if the case matches, otherwise `nil`.
  public static func `case`(_ value: Root) -> CasePath {
    let label = "\(value)"
    return CasePath(
      embed: { value },
      extract: { "\($0)" == label ? () : nil }
    )
  }
}

/// Attempts to extract values associated with a given enum case initializer from a given root enum.
/// 
///     extract(case: Result<Int, Error>.success, from: .success(42))
///     // 42
///     extract(case: Result<Int, Error>.success, from: .failure(MyError())
///     // nil
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameters:
///   - embed: An enum case initializer.
///   - root: A root enum value.
/// - Returns: Values iff they can be extracted from the given enum case initializer and root enum,
///   otherwise `nil`.
public func extract<Root, Value>(case embed: (Value) -> Root, from root: Root) -> Value? {
  func extractHelp(from root: Root) -> ([String?], Value)? {
    if let value = root as? Value {
      var otherRoot = embed(value)
      var root = root
      if memcmp(&root, &otherRoot, MemoryLayout<Root>.size) == 0 {
        return ([], value)
      }
    }
    var path: [String?] = []
    var any: Any = root

    while case let (label?, anyChild)? = Mirror(reflecting: any).children.first {
      path.append(label)
      path.append(String(describing: type(of: anyChild)))
      if let child = anyChild as? Value {
        return (path, child)
      }
      any = anyChild
    }
    if MemoryLayout<Value>.size == 0, !isUninhabitedEnum(Value.self) {
      return (["\(root)"], unsafeBitCast((), to: Value.self))
    }
    return nil
  }
  if let (rootPath, child) = extractHelp(from: root),
    let (otherPath, _) = extractHelp(from: embed(child)),
    rootPath == otherPath
  { return child }
  return nil
}

/// Returns a function that can attempt to extract associated values from the given enum case
/// initializer.
///
/// Use this function to create new transform functions to pass to higher-order methods like
/// `compactMap`:
///
///     [Result<Int, Error>.success(42), .failure(MyError()]
///       .compactMap(extract(Result.success))
///     // [42]
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameter case: An enum case initializer.
/// - Returns: A function that can attempt to extract associated values from an enum.
public func extract<Root, Value>(_ case: @escaping (Value) -> Root) -> (Root) -> (Value?) {
  return { root in
    return extract(case: `case`, from: root)
  }
}

// MARK: - Private Helpers

private struct EnumMetadata {
  let kind: Int
  let typeDescriptor: UnsafePointer<EnumTypeDescriptor>
}

private struct EnumTypeDescriptor {
  // These fields are not modeled because we don't need them.
  // They are the type descriptor flags and various pointer offsets.
  let flags, p1, p2, p3, p4: Int32
  
  let numPayloadCasesAndPayloadSizeOffset: Int32
  let numEmptyCases: Int32
  
  var numPayloadCases: Int32 {
    numPayloadCasesAndPayloadSizeOffset & 0xFFFFFF
  }
}

private func isUninhabitedEnum(_ type: Any.Type) -> Bool {
    // Load the type kind from the common type metadata area. Memory layout reference:
    // https://github.com/apple/swift/blob/master/docs/ABI/TypeMetadata.rst
    let metadataPtr = unsafeBitCast(type, to: UnsafeRawPointer.self)
    let metadataKind = metadataPtr.load(as: Int.self)
    
    // Check that this is an enum. Value reference:
    // https://github.com/apple/swift/blob/master/stdlib/public/core/ReflectionMirror.swift
    let isEnum = metadataKind == 0x201
    guard isEnum else { return false }
    
    // Access enum type descriptor
    let enumMetadata = metadataPtr.load(as: EnumMetadata.self)
    let enumTypeDescriptor = enumMetadata.typeDescriptor.pointee
    
    let numCases = enumTypeDescriptor.numPayloadCases + enumTypeDescriptor.numEmptyCases
    return numCases == 0
}
