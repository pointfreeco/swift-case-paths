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
  guard let metadata = EnumMetadata(Root.self) else {
    #if DEBUG
    print("\(#function) (#file:#line) can never extract values from \(Root.self) because \(Root.self) isn't an enum!")
    #endif
    return { _ in nil }
  }

  guard metadata.typeDescriptor.fieldDescriptor != nil else {
    #if DEBUG
    print("\(#function) (#file:#line) can never extract values from \(Root.self) because the metadata for \(Root.self) is incomplete!")
    #endif
    return { _ in nil }
  }

  var cachedExtractor: Extractor<Root, Value>? = nil
  return { root in
    if let extractor = cachedExtractor {
      return extractor.extract(from: root)
    }

    let metadata = EnumMetadata(assumingEnum: Root.self)

    #if true

    guard
      let rootExtractor = Extractor<Root, Value>(root: root),
      let value = rootExtractor.extract(from: root)
    else {
      return nil
    }

    let embedTag = metadata.tag(of: embed(value))
    guard embedTag == rootExtractor.tag else {
      // Well at least now I know the tag I'm looking for.
      cachedExtractor = .init(tag: embedTag)
      return nil
    }

    cachedExtractor = rootExtractor
    return value

    #else

    guard
      let value = (Mirror(reflecting: root).children.first?.value)
        .flatMap({ $0 as? Value ?? Mirror(reflecting: $0).children.first?.value as? Value })
        ?? workaroundForSR12044(Value.self)
    else {
      return nil
    }

    let embedTag = metadata.tag(of: embed(value))
    let extractor = Extractor<Root, Value>(tag: embedTag)
    cachedExtractor = extractor
    return metadata.tag(of: root) == embedTag ? value : nil

    #endif
  }
}

// MARK: - Private Helpers

// This is the size of any Unsafe*Pointer and also the size of Int and UInt.
private let pointerSize = MemoryLayout<UnsafeRawPointer>.size

private typealias OpaqueExistentialContainer = (
  UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?,
  metadata: UnsafeRawPointer?
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

  // This witness transforms an associated value into its enum value, in place.
  var destructiveInjectEnumData:
    @convention(c) (_ value: UnsafeMutableRawPointer, _ tag: UInt32, _ metadata: UnsafeRawPointer) -> Void
  {
    return ptr.advanced(by: 12 * pointerSize + 2 * 4).loadInferredType()
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
  // 0x301 = MetadataKind::Tuple
  static var enumeration: Self { .init(rawValue: 0x201) }
  static var optional: Self { .init(rawValue: 0x202) }
  static var tuple: Self { .init(rawValue: 0x301) }
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

private struct UnknownMetadata: Metadata {
  let ptr: UnsafeRawPointer

  var genericArguments: GenericArgumentVector? { nil }
}

extension UnknownMetadata {
  init(_ type: Any.Type) {
    ptr = unsafeBitCast(type, to: UnsafeRawPointer.self)
  }
}

private struct EnumMetadata: Metadata {
  let ptr: UnsafeRawPointer

  init(assumingEnum type: Any.Type) {
    ptr = unsafeBitCast(type, to: UnsafeRawPointer.self)
  }

  init?(_ type: Any.Type) {
    self.init(assumingEnum: type)
    guard kind == .enumeration || kind == .optional else { return nil }
  }

  var genericArguments: GenericArgumentVector? {
    guard isGeneric else { return nil }
    return .init(ptr: ptr.advanced(by: 2 * pointerSize))
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

  var numPayloadCases: Int32 {
    return ptr.advanced(by: 5 * 4).load(as: Int32.self) & 0xFFFFFF
  }
}

extension EnumMetadata {
  func associatedValueType(forTag tag: UInt32) -> Any.Type? {
    // If the tag represents a case without a payload, there's no type information stored for the tag. In that case, I can safely treat the payload as Void.
    guard tag < numPayloadCases else { return Void.self }

    guard
      let typeName = typeDescriptor.fieldDescriptor?.field(atIndex: tag).typeName
    else { return nil }

    return swift_getTypeByMangledNameInContext(
      typeName.ptr, typeName.length,
      genericContext: typeDescriptor.ptr,
      genericArguments: genericArguments?.ptr)
  }
}

extension EnumMetadata {
  func destructivelyProjectPayload(of value: UnsafeMutableRawPointer) {
    valueWitnessTable.destructiveProjectEnumData(value, ptr)
  }

  func destructivelyInjectTag(_ tag: UInt32, intoPayload payload: UnsafeMutableRawPointer) {
    valueWitnessTable.destructiveInjectEnumData(payload, tag, ptr)
  }
}

/// The strategy to use to extract the associated value of a specific case of `Enum` as a `Value`.
private enum Extractor<Enum, Value> {
  // The case is layout-compatible with `Value`, after tag-stripping (aka projection).
  case direct(tag: UInt32)

  // The case stores its associated value indirectly. The case payload is a pointer to a heap object. The heap object's payload is layout-compatible with `Value`.
  case indirect(tag: UInt32)

  // The case directly stores a protocol existential. `Value` conforms to that protocol.
  case directExistential(tag: UInt32)

  // The case indirectly stores a protocol existential. `Value` conforms to that protocol.
  case indirectExistential(tag: UInt32)
}

extension Extractor {
  var tag: UInt32 {
    switch self {
    case
      .direct(tag: let tag),
      .indirect(tag: let tag),
      .directExistential(tag: let tag),
      .indirectExistential(tag: let tag):
      return tag
    }
  }
}

extension Extractor {
  init(tag: UInt32) {
    self = EnumMetadata(assumingEnum: Enum.self)
      .typeDescriptor
      .fieldDescriptor!
      .field(atIndex: tag).isIndirectCase
      ? .indirect(tag: tag)
      : .direct(tag: tag)
  }
}

extension Extractor {
  init?(root: Enum) {
    let metadata = EnumMetadata(assumingEnum: Enum.self)
    let tag = metadata.tag(of: root)
    guard let avType = metadata.associatedValueType(forTag: tag) else { return nil }

    guard avType != Value.self else {
      self = .init(tag: tag)
      return
    }

    // Consider this: `enum E { case c(l: Int) }`
    //
    // At the metadata level, c's associated value has type `(l: Int)`, which is a single-element tuple.
    //
    // But Swift doesn't support single-element tuples in Swift source code, so `CasePath<E, (l: Int)>` isn't allowed.
    //
    // The case path for `c` therefore has type `CasePath<E, Int>`.
    //
    // The types `(l: Int)` and `Int` use the same memory layout.
    //
    // So if avType is a single-element tuple and Value is the type of that tuple's single element, I can extract a Value from root.
    if
      let tupleMetadata = TupleMetadata(avType),
      tupleMetadata.elementCount == 1,
      tupleMetadata.element(at: 0).type == Value.self
    {
      self = .init(tag: tag)
      return
    }

    return nil
  }
}

extension Extractor {
  func extract(from root: Enum) -> Value? {
    switch self {
    case .direct(let tag):
      return extractDirect(from: root, tag: tag)

    case .indirect(let tag):
      return extractIndirect(from: root, tag: tag)

    case .directExistential(tag: _):
      fatalError()

    case .indirectExistential(tag: _):
      fatalError()
    }
  }

  private func extractDirect(from root: Enum, tag: UInt32) -> Value? {
    guard EnumMetadata(assumingEnum: Enum.self).tag(of: root) == tag else { return nil }

    return withProjectedPayload(of: root, tag: tag) { .some($0.load(as: Value.self)) }
  }

  private func extractIndirect(from root: Enum, tag: UInt32) -> Value? {
    guard EnumMetadata(assumingEnum: Enum.self).tag(of: root) == tag else { return nil }

    return withProjectedPayload(of: root, tag: tag) {
      // In an indirect enum case, the payload is a pointer to a heap object. The heap object's payload is the associated value.
      return $0
        .load(as: UnsafeRawPointer.self) // Load the heap object pointer.
        .advanced(by: 2 * pointerSize) // Skip the heap object header.
        .load(as: Value.self)
    }
  }

  private func withProjectedPayload<Enum, Answer>(
    of root: Enum,
    tag: UInt32,
    do body: (UnsafeRawPointer) -> Answer
  ) -> Answer {
    var root = root
    let answer: Answer = withUnsafeMutableBytes(of: &root) { rawBuffer in
      let pointer = rawBuffer.baseAddress!
      let metadata = EnumMetadata(assumingEnum: Enum.self)

      // On entry, pointer points to some `Enum` value known to the Swift compiler. So on exit, it still needs to point to that `Enum` value, because the compiler wants to destroy the value in the usual way.

      metadata.destructivelyProjectPayload(of: pointer)
      // `pointer` now points to an `Enum` case payload. Tag bits have been set to zero as needed.

      let answer = body(pointer)

      metadata.destructivelyInjectTag(tag, intoPayload: pointer)
      // `pointer` now points to an `Enum` again.

      return answer
    }
    return answer
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

@_silgen_name("swift_getTypeByMangledNameInContext")
private func swift_getTypeByMangledNameInContext(
  _ name: UnsafePointer<UInt8>,
  _ nameLength: UInt,
  genericContext: UnsafeRawPointer?,
  genericArguments: UnsafeRawPointer?)
-> Any.Type?

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

  var typeName: MangledTypeName? {
    return ptr
      .advanced(by: 4)
      .loadRelativePointer()
      .map { MangledTypeName(ptr: $0.assumingMemoryBound(to: UInt8.self)) }
  }

  var isIndirectCase: Bool { flags.contains(.isIndirectCase) }
}

extension FieldRecord {
  struct Flags: OptionSet {
    var rawValue: UInt32

    static var isIndirectCase: Self { .init(rawValue: 1) }
  }
}

private struct MangledTypeName {
  let ptr: UnsafePointer<UInt8>

  var length: UInt {
    // Type name mangling is described here:
    // https://github.com/apple/swift/blob/main/docs/ABI/Mangling.rst
    // Since a mangled name can contain NUL bytes, I can't just use `strlen` or equivalent.

    var p = ptr
    while true {
      switch p.pointee {
      case 0:
        return UInt(bitPattern: p - ptr)
      case 0x01...0x17:
        // Relative symbolic reference.
        p = p.advanced(by: 5)
      case 0x18...0x1f:
        // Absolute symbolic reference
        p = p.advanced(by: 1 + pointerSize)
      default:
        // Just a humble character.
        p = p.advanced(by: 1)
      }
    }
  }
}

private struct TupleMetadata: Metadata {
  let ptr: UnsafeRawPointer

  init?(_ type: Any.Type) {
    ptr = unsafeBitCast(type, to: UnsafeRawPointer.self)
    guard kind == .tuple else { return nil }
  }

  var genericArguments: GenericArgumentVector? { nil }

  var elementCount: UInt { ptr.advanced(by: pointerSize).load(as: UInt.self) }

  func element(at i: Int) -> Element {
    return Element(
      ptr: ptr
        .advanced(by: pointerSize) // kind
        .advanced(by: pointerSize) // elementCount
        .advanced(by: pointerSize) // labels pointer
        .advanced(by: i * 2 * pointerSize))
  }
}

extension TupleMetadata {
  struct Element {
    let ptr: UnsafeRawPointer

    var type: Any.Type { ptr.load(as: Any.Type.self) }
    var offset: UInt { ptr.advanced(by: pointerSize).load(as: UInt.self) }
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
    var numEmptyCases: Int32 {
      return ptr.advanced(by: 6 * 4).load(as: Int32.self)
    }

    var isInhabited: Bool { numPayloadCases + numEmptyCases > 0 }
  }

#else

  private func workaroundForSR12044<Value>(_ type: Value.Type) -> Value? { nil }

#endif
