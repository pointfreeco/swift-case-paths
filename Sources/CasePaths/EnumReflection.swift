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
      extract: CasePaths.extract(embed)
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
public func extract<Root, Value>(case embed: @escaping (Value) -> Root, from root: Root) -> Value? {
  CasePaths.extract(embed)(root)
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
/// - Parameter embed: An enum case initializer.
/// - Returns: A function that can attempt to extract associated values from an enum.
public func extract<Root, Value>(_ embed: @escaping (Value) -> Root) -> (Root) -> (Value?) {
  var cachedTag: UInt32?
  return { root in
    guard let rootTag = enumTag(root) else { return nil }
    if let cachedTag = cachedTag, cachedTag != rootTag { return nil }
    let mirror = Mirror(reflecting: root)
    assert(mirror.displayStyle == .enum || mirror.displayStyle == .optional)
    guard
      let child = mirror.children.first,
      case let childMirror = Mirror(reflecting: child.value),
      let value = child.value as? Value ?? childMirror.children.first?.value as? Value
    else {
      #if compiler(<5.2)
        // https://bugs.swift.org/browse/SR-12044
        if MemoryLayout<Value>.size == 0, !isUninhabitedEnum(Value.self) {
          return unsafeBitCast((), to: Value.self)
        }
      #endif
      return nil
    }
    if rootTag == cachedTag { return value }
    guard let embedTag = enumTag(embed(value)) else { return nil }
    cachedTag = embedTag
    if rootTag == embedTag { return value }
    return nil
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

private func enumTag<Case>(_ `case`: Case) -> UInt32? {
  let metadataPtr = unsafeBitCast(type(of: `case`), to: UnsafeRawPointer.self)
  let kind = metadataPtr.load(as: Int.self)
  let isEnumOrOptional = kind == 0x201 || kind == 0x202
  guard isEnumOrOptional else { return nil }
  let vwtPtr = (metadataPtr - MemoryLayout<UnsafeRawPointer>.size).load(as: UnsafeRawPointer.self)
  let vwt = vwtPtr.load(as: EnumValueWitnessTable.self)
  return withUnsafePointer(to: `case`) { vwt.getEnumTag($0, metadataPtr) }
}

private struct EnumValueWitnessTable {
  let f1, f2, f3, f4, f5, f6, f7, f8: UnsafeRawPointer
  let f9, f10: Int
  let f11, f12: UInt32
  let getEnumTag: @convention(c) (UnsafeRawPointer, UnsafeRawPointer) -> UInt32
  let f13, f14: UnsafeRawPointer
}
