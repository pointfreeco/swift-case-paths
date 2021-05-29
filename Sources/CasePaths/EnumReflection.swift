import func Foundation.memcmp

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
@inlinable public func extract<Root, Value>(
  case embed: (Value) -> Root, from root: Root
) -> Value? {
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

    while let child = Mirror(reflecting: any).children.first, let label = child.label {
      path.append(label)
      path.append(String(describing: type(of: child.value)))
      if let child = child.value as? Value {
        return (path, child)
      }
      any = child.value
    }
    if MemoryLayout<Value>.size == 0, !isUninhabitedEnum(Value.self) {
      return (["\(root)"], unsafeBitCast((), to: Value.self))
    }
    return nil
  }
  if let (rootPath, child) = extractHelp(from: root),
    let (otherPath, _) = extractHelp(from: embed(child)),
    rootPath == otherPath
  {
    return child
  }
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
@inlinable public func extract<Root, Value>(
  _ case: @escaping (Value) -> Root
) -> (Root) -> (Value?) {
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

@usableFromInline func isUninhabitedEnum(_ type: Any.Type) -> Bool {
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
