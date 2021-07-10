
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
    print("\(#function) \(#file):\(#line) can never extract values from \(Root.self) because \(Root.self) isn't an enum!")
    #endif
    return { _ in nil }
  }

  guard metadata.typeDescriptor.fieldDescriptor != nil else {
    #if DEBUG
    print("\(#function) \(#file):\(#line) can never extract values from \(Root.self) because the metadata for \(Root.self) is incomplete!")
    #endif
    return { _ in nil }
  }

  var cachedExtractor: Extractor<Root, Value>? = nil
  return { root in
    let metadata = EnumMetadata(assumingEnum: Root.self)

    if let cachedTag = cachedExtractor?.tag {
      guard metadata.tag(of: root) == cachedTag else { return nil }
      return cachedExtractor.unsafelyUnwrapped.extract(from: root)
    }

    guard
      let rootExtractor = Extractor<Root, Value>(tag: metadata.tag(of: root)),
      let value = rootExtractor.extract(from: root)
    else {
      return nil
    }

    let embedTag = metadata.tag(of: embed(value))
    guard embedTag == rootExtractor.tag else {
      // Well at least now I know the tag I'm looking for.
      cachedExtractor = Extractor(tag: embedTag)
      return nil
    }

    cachedExtractor = rootExtractor
    return value
  }
}

// MARK: - Private Helpers

// This is the size of any Unsafe*Pointer and also the size of Int and UInt.
private let pointerSize = MemoryLayout<UnsafeRawPointer>.size

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
  // 0x303 = MetadataKind::Existential
  static var enumeration: Self { .init(rawValue: 0x201) }
  static var optional: Self { .init(rawValue: 0x202) }
  static var tuple: Self { .init(rawValue: 0x301) }
  static var existential: Self { .init(rawValue: 0x303) }
}

private protocol Metadata {
  var ptr: UnsafeRawPointer { get }
}

extension Metadata {
  var valueWitnessTable: ValueWitnessTable {
    return ValueWitnessTable(
      ptr: ptr.advanced(by: -pointerSize).load(as: UnsafeRawPointer.self))
  }

  var kind: MetadataKind { ptr.load(as: MetadataKind.self) }
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
    guard typeDescriptor.flags.contains(.isGeneric) else { return nil }
    return .init(ptr: ptr.advanced(by: 2 * pointerSize))
  }

  var typeDescriptor: EnumTypeDescriptor {
    return EnumTypeDescriptor(
      ptr: ptr.advanced(by: pointerSize).load(as: UnsafeRawPointer.self))
  }

  func tag<Enum>(of value: Enum) -> UInt32 {
    return withUnsafePointer(to: value) {
      valueWitnessTable.getEnumTag($0, self.ptr)
    }
  }
}

extension EnumMetadata {
  func associatedValueType(forTag tag: UInt32) -> Any.Type {
    guard
      let typeName = typeDescriptor.fieldDescriptor?.field(atIndex: tag).typeName,
      let type = swift_getTypeByMangledNameInContext(
        typeName.ptr, typeName.length,
        genericContext: typeDescriptor.ptr,
        genericArguments: genericArguments?.ptr)
    else {
      // There's not really a good answer for this. Void is a safe answer since it's zero-size.
      return Void.self
    }

    return type
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

private func isUninhabitedEnum(_ type: Any.Type) -> Bool {
  // If it lacks enum metadata, it's definitely not an uninhabited enum.
  guard let metadata = EnumMetadata(type) else { return false }
  return metadata.typeDescriptor.emptyCaseCount == 0
    && metadata.typeDescriptor.payloadCaseCount == 0
}

/// The strategy to use to extract the associated value of a specific case of `Enum` as a `Value`.
private enum Extractor<Enum, Value> {
  case unimplemented(tag: UInt32)

  /// The case's associated type is a zero-size inhabited type, so it only has a single possible inhabitant, which I can synthesize.
  case void(tag: UInt32)

  /// The case is layout-compatible with `Value`, after tag-stripping (aka projection).
  case direct(tag: UInt32)

  /// The case stores its associated value indirectly. The case payload is a pointer to a heap object. The heap object's payload is layout-compatible with `Value`.
  case indirect(tag: UInt32)

  /// The case stores a protocol existential, either directly or indirectly. This extractor type is only used when the enum case's associated value type is a protocol existential and the `CasePath`'s `Value` is a type that conforms to the protocol (but is not itself the protocol existential).
  case existential(tag: UInt32, get: (Enum) -> Any?)
}

extension Extractor {
  var tag: UInt32 {
    switch self {
    case
      .unimplemented(tag: let tag),
      .void(tag: let tag),
      .direct(tag: let tag),
      .indirect(tag: let tag),
      .existential(tag: let tag, get: _):
      return tag
    }
  }
}

extension Extractor {
  /// Create the appropriate `Extractor` to extract a `Value` from an `Enum` if that `Enum`'s case tag is `tag`. If `assumedAssociatedValueType` is nil, I'll look up the associated value type in the `Enum` metadata.
  init?(tag: UInt32, assumedAssociatedValueType: Any.Type? = nil) {
    let metadata = EnumMetadata(assumingEnum: Enum.self)
    let avType = assumedAssociatedValueType ?? metadata.associatedValueType(forTag: tag)

    var shouldWorkAroundSR12044: Bool {
      #if compiler(<5.2)
      return true
      #else
      return false
      #endif
    }

    if avType == Value.self {
      self = .init(nonExistentialTag: tag)
    }

    // If `Value` is an inhabited type with size zero, it has a single inhabitant which I can synthesize by bit-casting `()`.
    //
    // I handle this specially because it works around a Swift 5.1 bug:
    // https://bugs.swift.org/browse/SR-12044
    //
    // When the payload is a size-zero type, Swift 5.1 omits the typeName in the metadata describing the `tag` case, and `associatedValueType(forTag:)` returns `Void.self` in that case. This bug was corrected in Swift 5.2.
    //
    // An uninhabited type like Never also has a size of zero. I have to be careful not to create a value of an uninhabited type.
    //
    // If you do something like `enum E { case c(Never, Never) }`, I don't detect that it's an uninhabited tuple and I'll end up creating a bogus value of type `(Never, Never)` and it'll get passed to the `E.c` initializer. Remarkably, the initializer doesn't care! It creates the `E` value anyway. Since there is no safe way to create an `E.c` value, the `E.c` tag can't match the tag of the actual `E` value being checked by the `CasePath`. So the `CasePath` won't end up extracting a bogus value.
    else if
      shouldWorkAroundSR12044,
      MemoryLayout<Value>.size == 0,
      !isUninhabitedEnum(Value.self) {
      self = .void(tag: tag)
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
    // So if `avType` is a single-element tuple and `Value` is the type of that tuple's single element, I can extract a `Value` from `root`.
    else if
      let avMetadata = TupleMetadata(avType),
      avMetadata.elementCount == 1
    {
      self.init(tag: tag, assumedAssociatedValueType: avMetadata.element(at: 0).type)
    }

    // Consider this: `enum F { case d(a: Int, b: String) }`
    //
    // Certainly we should allow `CasePath<F, (a: Int, b: String)>` to match this.
    //
    // We would also like `CasePath<F, (Int, String)> to match this.
    //
    // So if `avType` is a tuple, and `Value` is a tuple with no labels, and the two types have identical elements types, I can extract a `Value` from `root`.
    //
    // If `Value` has labels, that doesn't change its memory layout. But I don't want to silently transform a tuple that was created as `(x: 1, y: 2)` into a differently-labeled tuple `(y: 1, x: 2)`.
    else if
      let avMetadata = TupleMetadata(avType),
      let valueMetadata = TupleMetadata(Value.self),
      valueMetadata.labels == nil
    {
      // Consider this:
      //
      // ```
      // protocol P { }
      // extension Int: P { }
      // enum Enum {
      //     case c(P, Int)
      // }
      // let (i: Int, j: Int)? = (/E.c).extract(E.c(34, 12))
      // ```
      //
      // See the handling of existentials later in this method for a simpler scenario that I do handle. But here, avType and Value are tuples with the same element count but different memory layout, because avType has a P existential where Value has an Int.
      //
      // This is an extremely rare scenario and I think it's too much work to try to handle it.
      guard avMetadata.hasSameLayout(as: valueMetadata) else {
        #if DEBUG
        print("CasePath<\(Enum.self), \(Value.self)> has not been programmed to convert an \(avType) to a \(Value.self).")
        #endif
        self = .unimplemented(tag: tag)
        return
      }

      self.init(tag: tag, assumedAssociatedValueType: Value.self)
      return
    }

    // Consider this:
    //
    // ```
    // protocol P { }
    // extension Int: P { }
    // enum E { case c(P) }
    //
    // let i: Int? = (/E.c).extract(E.c(100))
    // ```
    //
    // Even though the associated value type is `P`, and `E.c(_:)`'s type is `(P) -> E`, this constructs a `CasePath<E, Int>`, not a `CasePath<E, P>`. Here's why:
    //
    // - The context requires the `CasePath`'s `Value` type to be `Int`.
    //
    // - Therefore the `/` prefix operator requires its argument to have type `(Int) -> E`.
    //
    // - `(P) -> E` is a subtype of `(Int) -> E`, because `P` is in contravariant position and `Int` is a subtype of `P`.
    //
    // - Therefore Swift converts `E.c(_:)` to the supertype `(Int) -> E` automatically to make the expression type-check.
    //
    // This circumstance is unfortunate, but I don't know how to diagnose it at compile-time. So I want to handle it in a reasonable way.
    //
    // If `avType` is a protocol existential (a “box”), then I can extract the box from `root` and look at the boxed type. If the boxed type is `Value`, then I can extract `Value` from the box.
    //
    // Ideally I would check that Value actually conforms to avType's protocol. Unfortunately, the metedata doesn't include conformance information. I'd have to dig through the conformance sections of the executable file and shared libraries. It's not worth the trouble.
    else if
      ExistentialMetadata(avType) != nil
    {
      // I can use `Any` as the value type because it's compatible with any protocol existential.
      let anyExtractor = Extractor<Enum, Any>(nonExistentialTag: tag)
      self = .existential(tag: tag) { anyExtractor.extract(from: $0) }
    }

    else {
      return nil
    }
  }

  init(nonExistentialTag tag: UInt32) {
    self = EnumMetadata(assumingEnum: Enum.self)
      .typeDescriptor
      .fieldDescriptor!
      .field(atIndex: tag)
      .flags
      .contains(.isIndirectCase)
      ? .indirect(tag: tag)
      : .direct(tag: tag)
  }
}

extension Extractor {
  func extract(from root: Enum) -> Value? {
    switch self {
    case .unimplemented(tag: _):
      return nil

    case .void(tag: let tag):
      return extractVoid(from: root, tag: tag)

    case .direct(tag: let tag):
      return extractDirect(from: root, tag: tag)

    case .indirect(tag: let tag):
      return extractIndirect(from: root, tag: tag)

    case .existential(tag: let tag, get: let get):
      return extractThroughExistential(from: root, tag: tag, get: get)
    }
  }

  private func extractVoid(from root: Enum, tag: UInt32) -> Value? {
    guard EnumMetadata(assumingEnum: Enum.self).tag(of: root) == tag else { return nil }

    return .some(unsafeBitCast((), to: Value.self))
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

  private func extractThroughExistential(from root: Enum, tag: UInt32, get: (Enum) -> Any?) -> Value? {
    guard
      EnumMetadata(assumingEnum: Enum.self).tag(of: root) == tag,
      let any = get(root),
      let value = any as? Value
    else { return nil }
    return .some(value)
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

  var payloadCaseCount: UInt32 { ptr.advanced(by: 5 * 4).load(as: UInt32.self) & 0xffffff }

  var emptyCaseCount: UInt32 { ptr.advanced(by: 6 * 4).load(as: UInt32.self) }
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

  var elementCount: UInt {
    return ptr
      .advanced(by: pointerSize) // kind
      .load(as: UInt.self)
  }

  var labels: UnsafePointer<UInt8>? {
    return ptr
      .advanced(by: pointerSize) // kind
      .advanced(by: pointerSize) // elementCount
      .load(as: UnsafePointer<UInt8>?.self)
  }

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
  struct Element: Equatable {
    let ptr: UnsafeRawPointer

    var type: Any.Type { ptr.load(as: Any.Type.self) }
    var offset: UInt { ptr.advanced(by: pointerSize).load(as: UInt.self) }

    static func ==(lhs: Element, rhs: Element) -> Bool {
      return lhs.type == rhs.type && lhs.offset == rhs.offset
    }
  }
}

extension TupleMetadata {
  func hasSameLayout(as other: TupleMetadata) -> Bool {
    return self.elementCount == other.elementCount &&
      (0 ..< Int(elementCount)).allSatisfy { self.element(at: $0) == other.element(at: $0) }
  }
}

private struct ExistentialMetadata: Metadata {
  let ptr: UnsafeRawPointer

  init?(_ type: Any.Type?) {
    ptr = unsafeBitCast(type, to: UnsafeRawPointer.self)
    guard kind == .existential else { return nil }
  }
}
