import CCasePaths

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
/// ```swift
/// extract(case: Result<Int, Error>.success, from: .success(42))
/// // 42
/// extract(case: Result<Int, Error>.success, from: .failure(MyError())
/// // nil
/// ```
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
/// ```swift
/// [Result<Int, Error>.success(42), .failure(MyError()]
///   .compactMap(extract(Result.success))
/// // [42]
/// ```
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameter embed: An enum case initializer.
/// - Returns: A function that can attempt to extract associated values from an enum.
public func extract<Root, Value>(_ embed: @escaping (Value) -> Root) -> (Root) -> (Value?) {
  var cachedTag: UInt32?
  return { root in
    guard let metadata = EnumMetadata(Root.self) else { return nil }
    let rootTag = metadata.tag(of: root)

    if let cachedTag = cachedTag {
      guard
        cachedTag == rootTag,
        let fieldDescriptor = metadata.typeDescriptor.fieldDescriptor
        else { return nil }
      return .some(
        fieldDescriptor.field(atIndex: rootTag).isIndirectCase
          ? metadata.indirectAssociatedValue(of: root, as: Value.self)
          : metadata.directAssociatedValue(of: root, as: Value.self))
    }

    guard
      let value = (Mirror(reflecting: root).children.first?.value)
        .flatMap({ $0 as? Value ?? Mirror(reflecting: $0).children.first?.value as? Value })
        ?? workaroundForSR12044(Value.self)
    else {
      return nil
    }
    let embedTag = metadata.tag(of: embed(value))
    cachedTag = embedTag
    if rootTag == embedTag { return value }
    return nil
  }
}

// MARK: - Private Helpers

// This is the size of any Unsafe*Pointer and also the size of Int and UInt.
private let pointerSize = MemoryLayout<UnsafeRawPointer>.size

private typealias OpaqueExistentialContainer = (
  UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?,
  metadata: UnsafeMutableRawPointer?
)

private typealias BoxPair = (heapObject: UnsafeMutableRawPointer, buffer: UnsafeMutableRawPointer)

extension UnsafeRawPointer {
  fileprivate func loadInferredType<Type>() -> Type {
    return load(as: Type.self)
  }

  fileprivate func loadRelativePointer() -> UnsafeRawPointer? {
    let offset = Int(load(as: Int32.self))
    return offset == 0 ? nil : self + offset
  }
}

private struct ValueWitnessTable {
  let ptr: UnsafeRawPointer

  var flags: Flags {
    return Flags(rawValue: ptr.advanced(by: 10 * pointerSize).load(as: UInt32.self))
  }

  var initializeWithCopy:
    @convention(c) (
      _ dest: UnsafeMutableRawPointer, _ source: UnsafeMutableRawPointer,
      _ metadata: UnsafeRawPointer
    ) -> UnsafeMutableRawPointer
  {
    return ptr.advanced(by: 2 * pointerSize).loadInferredType()
  }

  var initializeWithTake:
    @convention(c) (
      _ dest: UnsafeMutableRawPointer, _ source: UnsafeMutableRawPointer,
      _ metadata: UnsafeRawPointer
    ) -> UnsafeMutableRawPointer
  {
    return ptr.advanced(by: 4 * pointerSize).loadInferredType()
  }

  var getEnumTag: @convention(c) (_ value: UnsafeRawPointer, _ metadata: UnsafeRawPointer) -> UInt32
  {
    return ptr.advanced(by: 10 * pointerSize + 2 * 4).loadInferredType()
  }

  // This witness transforms an enum value into its associated value, in place.
  var destructiveProjectEnumData:
    @convention(c) (_ value: UnsafeMutableRawPointer, _ metadata: UnsafeRawPointer) -> Void
  {
    return ptr.advanced(by: 11 * pointerSize + 2 * 4).loadInferredType()
  }
}

extension ValueWitnessTable {
  struct Flags: OptionSet {
    var rawValue: UInt32

    static var isNonInline: Self { .init(rawValue: 0x020000) }
  }
}

private struct GenericArgumentVector {
  let ptr: UnsafeRawPointer
}

private struct MetadataKind: Equatable {
  var rawValue: UInt

  // https://github.com/apple/swift/blob/main/include/swift/ABI/MetadataValues.h
  // https://github.com/apple/swift/blob/main/include/swift/ABI/MetadataKind.def
  // 0x201 = MetadataKind::Enum
  // 0x202 = MetadataKind::Optional
  static var enumeration: Self { .init(rawValue: 0x201) }
  static var optional: Self { .init(rawValue: 0x202) }
}

private protocol Metadata {
  var ptr: UnsafeRawPointer { get }

  var genericArguments: GenericArgumentVector? { get }
}

extension Metadata {
  var valueWitnessTable: ValueWitnessTable {
    return ValueWitnessTable(
      ptr: ptr.advanced(by: -pointerSize).load(as: UnsafeRawPointer.self))
  }

  var kind: MetadataKind { ptr.load(as: MetadataKind.self) }

  func initialize(_ dest: UnsafeMutableRawPointer, byCopying source: UnsafeMutableRawPointer) {
    _ = valueWitnessTable.initializeWithCopy(dest, source, ptr)
  }

  func initialize(_ dest: UnsafeMutableRawPointer, byTaking source: UnsafeMutableRawPointer) {
    _ = valueWitnessTable.initializeWithTake(dest, source, ptr)
  }
}

private struct NativeObjectMetadata: Metadata {
  let ptr: UnsafeRawPointer

  var genericArguments: GenericArgumentVector? { nil }
}

private struct EnumMetadata: Metadata {
  let ptr: UnsafeRawPointer

  var genericArguments: GenericArgumentVector? {
    guard isGeneric else { return nil }
    return .init(ptr: ptr.advanced(by: 2 * pointerSize))
  }

  init?(_ type: Any.Type) {
    ptr = unsafeBitCast(type, to: UnsafeRawPointer.self)
    guard kind == .enumeration || kind == .optional else { return nil }
  }

  var typeDescriptor: EnumTypeDescriptor {
    return EnumTypeDescriptor(
      ptr: ptr.advanced(by: pointerSize).load(as: UnsafeRawPointer.self))
  }

  var isGeneric: Bool { typeDescriptor.flags.contains(.isGeneric) }

  func tag<Enum>(of value: Enum) -> UInt32 {
    return withUnsafePointer(to: value) {
      valueWitnessTable.getEnumTag($0, self.ptr)
    }
  }

  func directAssociatedValue<Enum, Value>(of enumCase: Enum, as type: Value.Type) -> Value {
    let enumPtr = UnsafeMutablePointer<Enum>.allocate(capacity: 1)
    enumPtr.initialize(to: enumCase)

    let untypedPtr = UnsafeMutableRawPointer(enumPtr)
    valueWitnessTable.destructiveProjectEnumData(untypedPtr, ptr)

    let valuesPtr = untypedPtr.assumingMemoryBound(to: Value.self)
    let values = valuesPtr.pointee

    valuesPtr.deinitialize(count: 1)
    valuesPtr.deallocate()

    return values
  }

  func indirectAssociatedValue<Enum, Value>(of enumCase: Enum, as type: Value.Type) -> Value {
    // This is closely based on EnumImpl::subscript.
    // https://github.com/apple/swift/blob/main/stdlib/public/runtime/ReflectionMirror.cpp

    // I'll need access to this thing's bytes, which means it has to be a var.
    var enumCase = enumCase

    // Storage for an existential container with no conformances. In the C++ code, this is declared `Any enumCopy`, but `Any` is a `using` alias for `OpaqueExistentialContainer`.
    var enumCopy = OpaqueExistentialContainer(nil, nil, nil, metadata: nil)

    let answer: Value = withUnsafeMutablePointer(to: &enumCopy) { enumCopy in
      // A “box” here means a value stored as the payload of a HeapObject.

      let enumCopyContainer = allocateBoxForExistential(in: enumCopy)
      initialize(enumCopyContainer, byCopying: &enumCase)

      valueWitnessTable.destructiveProjectEnumData(enumCopyContainer, ptr)

      // Note that this getter returns the pointer to the “full” metadata, which must be advanced by a word to become a normal metadata pointer.
      let boxType = NativeObjectMetadata(
        ptr: getBuiltinNativeObjectFullMetadata()!.advanced(by: pointerSize))
      let pair = swift_allocBox(for: boxType.ptr)
      boxType.initialize(pair.buffer, byTaking: enumCopyContainer)
      deallocateBoxForExistential(in: enumCopy)

      var valuePtr = pair.buffer
      // The payload is always indirect in this method, so we have to open the box.
      valuePtr = valuePtr.load(as: UnsafeMutableRawPointer.self)
      valuePtr = swift_projectBox(valuePtr)

      let value = valuePtr.load(as: type)
      swift_release(pair.heapObject)
      return value
    }

    return answer
  }

  func allocateBoxForExistential(in buffer: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
    guard valueWitnessTable.flags.contains(.isNonInline) else {
      return buffer
    }

    let (heapObject:heapObject, buffer:boxBuffer) = swift_allocBox(for: ptr)
    buffer.storeBytes(of: heapObject, as: UnsafeMutableRawPointer.self)
    return boxBuffer
  }

  func deallocateBoxForExistential(in buffer: UnsafeMutableRawPointer) {
    guard valueWitnessTable.flags.contains(.isNonInline) else { return }
    swift_deallocBox(buffer.load(as: UnsafeMutableRawPointer.self))
  }
}

@_silgen_name("swift_allocBox")
private func swift_allocBox(for metadata: UnsafeRawPointer) -> BoxPair

@_silgen_name("swift_deallocBox")
private func swift_deallocBox(_ heapObject: UnsafeMutableRawPointer)

@_silgen_name("swift_projectBox")
private func swift_projectBox(_ heapObject: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer

@_silgen_name("swift_release")
private func swift_release(_ heapObject: UnsafeMutableRawPointer)

private struct EnumTypeDescriptor {
  let ptr: UnsafeRawPointer

  var flags: Flags { Flags(rawValue: ptr.load(as: UInt32.self)) }

  var fieldDescriptor: FieldDescriptor? {
    return ptr
      .advanced(by: 4 * 4)
      .loadRelativePointer()
      .map(FieldDescriptor.init)
  }
}

extension EnumTypeDescriptor {
  struct Flags: OptionSet {
    let rawValue: UInt32

    static var isGeneric: Self { .init(rawValue: 0x80) }
  }
}

private struct FieldDescriptor {
  let ptr: UnsafeRawPointer

  /// The size of a FieldRecord as stored in the executable.
  var recordSize: Int { Int(ptr.advanced(by: 2 * 4 + 2).load(as: UInt16.self)) }

  func field(atIndex i: UInt32) -> FieldRecord {
    return FieldRecord(
      ptr: ptr.advanced(by: 2 * 4 + 2 * 2 + 4).advanced(by: Int(i) * recordSize))
  }
}

private struct FieldRecord {
  let ptr: UnsafeRawPointer

  var flags: Flags { Flags(rawValue: ptr.load(as: UInt32.self)) }

  var isIndirectCase: Bool { flags.contains(.isIndirectCase) }
}

extension FieldRecord {
  struct Flags: OptionSet {
    var rawValue: UInt32

    static var isIndirectCase: Self { .init(rawValue: 1) }
  }
}

#if compiler(<5.2)

  // https://bugs.swift.org/browse/SR-12044
  private func workaroundForSR12044<Value>(_ type: Value.Type) -> Value? {
    // If Value is an inhabited type with a size of zero, Mirror doesn't notice it as the associated value of an enum case due to incorrect metadata. But, being inhabited with a size of zero, it has only one possible inhabitant, so I create the inhabitant here using unsafeBitCast.

    // An uninhabited type like Never also has a size of zero, and I have to be careful not to create a value of an uninhabited type.

    // It's possible for a tuple, struct, or class to be uninhabited by having an uninhabited stored property. But detecting such a type is difficult as I'd have to scrounge through even more metadata. So instead I'm just checking for the common case of an uninhabited enum. If you do something like `enum E { case c(Never, Never) }`... you have my sincere apology.

    if MemoryLayout<Value>.size == 0,
      !isUninhabitedEnum(Value.self)
    {
      return unsafeBitCast((), to: Value.self)
    }
    return nil
  }

  private func isUninhabitedEnum(_ type: Any.Type) -> Bool {
    // If it lacks enum metadata, it's definitely not an uninhabited enum.
    guard let metadata = EnumMetadata(type) else { return false }
    return !metadata.typeDescriptor.isInhabited
  }

  extension EnumTypeDescriptor {
    var numPayloadCases: Int32 {
      return ptr.advanced(by: 5 * 4).load(as: Int32.self) & 0xFFFFFF
    }

    var numEmptyCases: Int32 {
      return ptr.advanced(by: 6 * 4).load(as: Int32.self)
    }

    var isInhabited: Bool { numPayloadCases + numEmptyCases > 0 }
  }

#else

  private func workaroundForSR12044<Value>(_ type: Value.Type) -> Value? { nil }

#endif
