extension CasePath {
  /// Returns a case path for the given embed function.
  ///
  /// - Note: This operator is only intended to be used with enum cases that have no associated
  ///   values. Its behavior is otherwise undefined.
  /// - Parameter embed: An embed function.
  /// - Returns: A case path.
  public init(_ embed: @escaping (Value) -> Root) {
    func open<Wrapped>(_: Wrapped.Type) -> (Root) -> Value? {
      optionalPromotedExtractHelp(unsafeBitCast(embed, to: ((Value) -> Wrapped?).self))
        as! (Root) -> Value?
    }
    let extract =
      ((_Witness<Root>.self as? _AnyOptional.Type)?.wrappedType)
      .map { _openExistential($0, do: open) }
      ?? extractHelp(embed)
    self.init(
      embed: embed,
      extract: extract
    )
  }
}

extension CasePath where Value == Void {
  /// Returns a void case path for a case with no associated value.
  ///
  /// - Note: This operator is only intended to be used with enum cases that have no associated
  ///   values. Its behavior is otherwise undefined.
  /// - Parameter root: A case with no an associated value.
  /// - Returns: A void case path.
  public init(_ root: Root) {
    func open<Wrapped>(_: Wrapped.Type) -> (Root) -> Void? {
      optionalPromotedExtractVoidHelp(unsafeBitCast(root, to: Wrapped?.self)) as! (Root) -> Void?
    }
    let extract =
      ((_Witness<Root>.self as? _AnyOptional.Type)?.wrappedType)
      .map { _openExistential($0, do: open) }
      ?? extractVoidHelp(root)
    self.init(embed: { root }, extract: extract)
  }
}

extension CasePath where Root == Value {
  /// Returns the identity case path for the given type. Enables `CasePath(MyType.self)` syntax.
  ///
  /// - Parameter type: A type for which to return the identity case path.
  /// - Returns: An identity case path.
  public init(_ type: Root.Type) {
    self = .self
  }
}

extension CasePath {
  /// Returns a case path that extracts values associated with a given enum case initializer.
  ///
  /// - Note: This function is only intended to be used with enum case initializers. Its behavior is
  ///   otherwise undefined.
  /// - Parameter embed: An enum case initializer.
  /// - Returns: A case path that extracts associated values from enum cases.
  @available(*, deprecated, message: "Use case path literal syntax (e.g., '/Root.caseName')")
  public static func `case`(_ embed: @escaping (Value) -> Root) -> CasePath {
    self.init(
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
  @available(*, deprecated, message: "Use case path literal syntax (e.g., '/Root.caseName')")
  public static func `case`(_ value: Root) -> CasePath {
    CasePath(
      embed: { value },
      extract: extractVoidHelp(value)
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
/// - Returns: Values if they can be extracted from the given enum case initializer and root enum,
///   otherwise `nil`.
@available(
  *, deprecated,
  message:
    "Use case path literal syntax (e.g., '/Root.caseName'), or '(/Root.caseName).extract(from:)'"
)
public func extract<Root, Value>(case embed: @escaping (Value) -> Root, from root: Root) -> Value? {
  CasePaths.extract(embed)(root)
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
/// - Returns: Values if they can be extracted from the given enum case initializer and root enum,
///   otherwise `nil`.
@available(
  *, deprecated,
  message:
    "Use case path literal syntax (e.g., '/Root.caseName'), or '(/Root.caseName).extract(from:)'"
)
public func extract<Root, Value>(case embed: @escaping (Value) -> Root?, from root: Root?) -> Value?
{
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
@available(*, deprecated, message: "Use case path literal syntax (e.g., '/Root.caseName')")
public func extract<Root, Value>(_ embed: @escaping (Value) -> Root) -> (Root) -> Value? {
  extractHelp(embed)
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
@available(*, deprecated, message: "Use case path literal syntax (e.g., '/Root.caseName')")
public func extract<Root, Value>(_ embed: @escaping (Value) -> Root?) -> (Root?) -> Value? {
  optionalPromotedExtractHelp(embed)
}

// MARK: - Extraction helpers

func extractHelp<Root, Value>(_ embed: @escaping (Value) -> Root) -> (Root) -> Value? {
  guard
    let metadata = EnumMetadata(Root.self),
    metadata.typeDescriptor.fieldDescriptor != nil
  else {
    assertionFailure("embed parameter must be a valid enum case initializer")
    return { _ in nil }
  }

  var cachedTag: UInt32?
  var cachedStrategy: Strategy<Root, Value>?

  return { root in
    let rootTag = metadata.tag(of: root)

    if let cachedTag = cachedTag, let cachedStrategy = cachedStrategy {
      guard rootTag == cachedTag else { return nil }
      return cachedStrategy.extract(from: root, tag: rootTag)
    }

    let rootStrategy = Strategy<Root, Value>(tag: rootTag)
    guard let value = rootStrategy.extract(from: root, tag: rootTag)
    else { return nil }

    let embedTag = metadata.tag(of: embed(value))
    cachedTag = embedTag
    if embedTag == rootTag {
      cachedStrategy = rootStrategy
      return value
    } else {
      cachedStrategy = Strategy<Root, Value>(tag: embedTag)
      return nil
    }
  }
}

func optionalPromotedExtractHelp<Root, Value>(
  _ embed: @escaping (Value) -> Root?
) -> (Root?) -> Value? {
  guard Root.self != Value.self else { return { $0 as! Value? } }
  guard
    let metadata = EnumMetadata(Root.self),
    metadata.typeDescriptor.fieldDescriptor != nil
  else {
    assertionFailure("embed parameter must be a valid enum case initializer")
    return { _ in nil }
  }

  var cachedTag: UInt32?
  var cachedStrategy: Strategy<Root, Value>?

  return { optionalRoot in
    guard let root = optionalRoot else { return nil }

    let rootTag = metadata.tag(of: root)

    if let cachedTag = cachedTag, let cachedStrategy = cachedStrategy {
      guard rootTag == cachedTag else { return nil }
      return cachedStrategy.extract(from: root, tag: rootTag)
    }

    let rootStrategy = Strategy<Root, Value>(tag: rootTag)
    guard let value = rootStrategy.extract(from: root, tag: rootTag)
    else { return nil }

    guard let embedded = embed(value) else { return nil }
    let embedTag = metadata.tag(of: embedded)
    cachedTag = embedTag
    if embedTag == rootTag {
      cachedStrategy = rootStrategy
      return value
    } else {
      cachedStrategy = Strategy<Root, Value>(tag: embedTag)
      return nil
    }
  }
}

func extractVoidHelp<Root>(_ root: Root) -> (Root) -> Void? {
  guard
    let metadata = EnumMetadata(Root.self),
    metadata.typeDescriptor.fieldDescriptor != nil
  else {
    assertionFailure("value must be a valid enum case")
    return { _ in nil }
  }

  let cachedTag = metadata.tag(of: root)
  return { root in metadata.tag(of: root) == cachedTag ? () : nil }
}

func optionalPromotedExtractVoidHelp<Root>(_ root: Root?) -> (Root?) -> Void? {
  guard
    let root = root,
    let metadata = EnumMetadata(Root.self),
    metadata.typeDescriptor.fieldDescriptor != nil
  else {
    assertionFailure("value must be a valid enum case")
    return { _ in nil }
  }

  let cachedTag = metadata.tag(of: root)
  return { root in root.flatMap(metadata.tag(of:)) == cachedTag ? () : nil }
}

// MARK: - Runtime reflection

private enum Strategy<Enum, Value> {
  case direct
  case existential(extract: (Enum) -> Any?)
  case indirect
  case optional(extract: (Enum) -> Value?)
  case unimplemented
  case void
}

extension Strategy {
  init(tag: UInt32, assumedAssociatedValueType: Any.Type? = nil) {
    let metadata = EnumMetadata(assumingEnum: Enum.self)
    let avType = assumedAssociatedValueType ?? metadata.associatedValueType(forTag: tag)

    var shouldWorkAroundSR12044: Bool {
      #if compiler(<5.2)
        return true
      #else
        return false
      #endif
    }

    var isUninhabitedEnum: Bool {
      metadata.typeDescriptor.emptyCaseCount == 0 && metadata.typeDescriptor.payloadCaseCount == 0
    }

    if avType == Value.self {
      self = .init(nonExistentialTag: tag)

    } else if shouldWorkAroundSR12044, MemoryLayout<Value>.size == 0, !isUninhabitedEnum {
      // Workaround for https://bugs.swift.org/browse/SR-12044
      self = .void

    } else if let avMetadata = TupleMetadata(avType), avMetadata.elementCount == 1 {
      // Drop payload label from metadata, e.g., treat `(foo: Foo)` as `Foo`.
      self.init(tag: tag, assumedAssociatedValueType: avMetadata.element(at: 0).type)

    } else if let avMetadata = TupleMetadata(avType),
      let valueMetadata = TupleMetadata(Value.self),
      valueMetadata.labels == nil
    {
      // Drop payload labels from metadata, e.g., treat `(foo: Foo, bar: Bar)` as `(Foo, Bar)`.
      guard avMetadata.hasSameLayout(as: valueMetadata) else {
        self = .unimplemented
        return
      }
      self.init(tag: tag, assumedAssociatedValueType: Value.self)

    } else if let avMetadata = ExistentialMetadata(avType) {
      if avType == Error.self || avMetadata.isClassConstrained {
        // For Objective-C interop, the Error existential is a pointer to an NSError-compatible
        // (and thus AnyObject-compatible) object.
        let strategy = Strategy<Enum, AnyObject>(nonExistentialTag: tag)
        self = .existential { strategy.extract(from: $0, tag: tag) }
        return
      }

      // Convert protocol existentials to `Any` so that they can be cast (`as? Value`).
      let anyStrategy = Strategy<Enum, Any>(nonExistentialTag: tag)
      self = .existential { anyStrategy.extract(from: $0, tag: tag) }

    } else if avType == Value?.self {
      // Handle contravariant optional demotion, e.g. embed function
      // `(String?) -> Result<String?, Error>)` interpreted as `(String) -> Result<String?, Error>`
      let wrappedStrategy = Strategy<Enum, Value?>(tag: tag, assumedAssociatedValueType: avType)
      if case .unimplemented = wrappedStrategy {
        self = .unimplemented
      } else {
        self = .optional { wrappedStrategy.extract(from: $0, tag: tag).flatMap { $0 } }
      }
    } else {
      self = .unimplemented
    }
  }

  init(nonExistentialTag tag: UInt32) {
    self =
      EnumMetadata(assumingEnum: Enum.self)
        .typeDescriptor
        .fieldDescriptor!
        .field(atIndex: tag)
        .flags
        .contains(.isIndirectCase)
      ? .indirect
      : .direct
  }

  func extract(from root: Enum, tag: UInt32) -> Value? {
    switch self {
    case .direct:
      return self.withProjectedPayload(of: root, tag: tag) { $0.load(as: Value.self) }

    case let .existential(extract):
      return extract(root) as? Value

    case .indirect:
      return self.withProjectedPayload(of: root, tag: tag) {
        $0
          .load(as: UnsafeRawPointer.self)  // Load the heap object pointer.
          .advanced(by: 2 * pointerSize)  // Skip the heap object header.
          .load(as: Value.self)
      }

    case let .optional(extract):
      return extract(root)

    case .unimplemented:
      return nil

    case .void:
      return .some(unsafeBitCast((), to: Value.self))
    }
  }

  private func withProjectedPayload<Answer>(
    of root: Enum,
    tag: UInt32,
    do body: (UnsafeRawPointer) -> Answer
  ) -> Answer {
    var root = root
    return withUnsafeMutableBytes(of: &root) { rawBuffer in
      let pointer = rawBuffer.baseAddress!
      let metadata = EnumMetadata(assumingEnum: Enum.self)
      metadata.destructivelyProjectPayload(of: pointer)
      defer { metadata.destructivelyInjectTag(tag, intoPayload: pointer) }
      return body(pointer)
    }
  }
}

private protocol Metadata {
  var ptr: UnsafeRawPointer { get }
}

extension Metadata {
  var valueWitnessTable: ValueWitnessTable {
    ValueWitnessTable(
      ptr: self.ptr.load(fromByteOffset: -pointerSize, as: UnsafeRawPointer.self)
    )
  }

  var kind: MetadataKind { self.ptr.load(as: MetadataKind.self) }
}

private struct MetadataKind: Equatable {
  var rawValue: UInt

  // https://github.com/apple/swift/blob/main/include/swift/ABI/MetadataValues.h
  // https://github.com/apple/swift/blob/main/include/swift/ABI/MetadataKind.def
  static var enumeration: Self { .init(rawValue: 0x201) }
  static var optional: Self { .init(rawValue: 0x202) }
  static var tuple: Self { .init(rawValue: 0x301) }
  static var existential: Self { .init(rawValue: 0x303) }
}

private struct EnumMetadata: Metadata {
  let ptr: UnsafeRawPointer

  init(assumingEnum type: Any.Type) {
    self.ptr = unsafeBitCast(type, to: UnsafeRawPointer.self)
  }

  init?(_ type: Any.Type) {
    self.init(assumingEnum: type)
    guard self.kind == .enumeration || self.kind == .optional else { return nil }
  }

  var genericArguments: GenericArgumentVector? {
    guard typeDescriptor.flags.contains(.isGeneric) else { return nil }
    return .init(ptr: self.ptr.advanced(by: 2 * pointerSize))
  }

  var typeDescriptor: EnumTypeDescriptor {
    EnumTypeDescriptor(
      ptr: self.ptr.load(fromByteOffset: pointerSize, as: UnsafeRawPointer.self)
    )
  }

  func tag<Enum>(of value: Enum) -> UInt32 {
    // NB: Workaround for https://github.com/apple/swift/issues/61708
    guard self.typeDescriptor.emptyCaseCount + self.typeDescriptor.payloadCaseCount > 1
    else { return 0 }
    return withUnsafePointer(to: value) {
      self.valueWitnessTable.getEnumTag($0, self.ptr)
    }
  }
}

extension EnumMetadata {
  func associatedValueType(forTag tag: UInt32) -> Any.Type {
    guard
      let typeName = self.typeDescriptor.fieldDescriptor?.field(atIndex: tag).typeName,
      let type = swift_getTypeByMangledNameInContext(
        typeName.ptr, typeName.length,
        genericContext: self.typeDescriptor.ptr,
        genericArguments: self.genericArguments?.ptr
      )
    else {
      return Void.self
    }

    return type
  }
}

@_silgen_name("swift_getTypeByMangledNameInContext")
private func swift_getTypeByMangledNameInContext(
  _ name: UnsafePointer<UInt8>,
  _ nameLength: UInt,
  genericContext: UnsafeRawPointer?,
  genericArguments: UnsafeRawPointer?
)
  -> Any.Type?

extension EnumMetadata {
  func destructivelyProjectPayload(of value: UnsafeMutableRawPointer) {
    self.valueWitnessTable.destructiveProjectEnumData(value, ptr)
  }

  func destructivelyInjectTag(_ tag: UInt32, intoPayload payload: UnsafeMutableRawPointer) {
    self.valueWitnessTable.destructiveInjectEnumData(payload, tag, ptr)
  }
}

private struct EnumTypeDescriptor: Equatable {
  let ptr: UnsafeRawPointer

  var flags: Flags { Flags(rawValue: self.ptr.load(as: UInt32.self)) }

  var fieldDescriptor: FieldDescriptor? {
    self.ptr
      .advanced(by: 4 * 4)
      .loadRelativePointer()
      .map(FieldDescriptor.init)
  }

  var payloadCaseCount: UInt32 { self.ptr.load(fromByteOffset: 5 * 4, as: UInt32.self) & 0xFFFFFF }

  var emptyCaseCount: UInt32 { self.ptr.load(fromByteOffset: 6 * 4, as: UInt32.self) }
}

extension EnumTypeDescriptor {
  struct Flags: OptionSet {
    let rawValue: UInt32

    static var isGeneric: Self { .init(rawValue: 0x80) }
  }
}

private struct TupleMetadata: Metadata {
  let ptr: UnsafeRawPointer

  init?(_ type: Any.Type) {
    self.ptr = unsafeBitCast(type, to: UnsafeRawPointer.self)
    guard self.kind == .tuple else { return nil }
  }

  var elementCount: UInt {
    self.ptr
      .advanced(by: pointerSize)  // kind
      .load(as: UInt.self)
  }

  var labels: UnsafePointer<UInt8>? {
    self.ptr
      .advanced(by: pointerSize)  // kind
      .advanced(by: pointerSize)  // elementCount
      .load(as: UnsafePointer<UInt8>?.self)
  }

  func element(at i: Int) -> Element {
    Element(
      ptr:
        self.ptr
        .advanced(by: pointerSize)  // kind
        .advanced(by: pointerSize)  // elementCount
        .advanced(by: pointerSize)  // labels pointer
        .advanced(by: i * 2 * pointerSize)
    )
  }
}

extension TupleMetadata {
  struct Element: Equatable {
    let ptr: UnsafeRawPointer

    var type: Any.Type { self.ptr.load(as: Any.Type.self) }

    var offset: UInt32 { self.ptr.load(fromByteOffset: pointerSize, as: UInt32.self) }

    static func == (lhs: Element, rhs: Element) -> Bool {
      lhs.type == rhs.type && lhs.offset == rhs.offset
    }
  }
}

extension TupleMetadata {
  func hasSameLayout(as other: TupleMetadata) -> Bool {
    self.elementCount == other.elementCount
      && (0..<Int(self.elementCount)).allSatisfy { self.element(at: $0) == other.element(at: $0) }
  }
}

private struct ExistentialMetadata: Metadata {
  let ptr: UnsafeRawPointer

  init?(_ type: Any.Type?) {
    self.ptr = unsafeBitCast(type, to: UnsafeRawPointer.self)
    guard self.kind == .existential else { return nil }
  }

  var isClassConstrained: Bool {
    self.ptr.advanced(by: pointerSize).load(as: UInt32.self) & 0x8000_0000 == 0
  }
}

private struct FieldDescriptor {
  let ptr: UnsafeRawPointer

  /// The size of a FieldRecord as stored in the executable.
  var recordSize: Int { Int(self.ptr.advanced(by: 2 * 4 + 2).load(as: UInt16.self)) }

  func field(atIndex i: UInt32) -> FieldRecord {
    FieldRecord(
      ptr: self.ptr.advanced(by: 2 * 4 + 2 * 2 + 4).advanced(by: Int(i) * recordSize)
    )
  }
}

private struct FieldRecord {
  let ptr: UnsafeRawPointer

  var flags: Flags { Flags(rawValue: self.ptr.load(as: UInt32.self)) }

  var typeName: MangledTypeName? {
    self.ptr
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
    // https://github.com/apple/swift/blob/main/docs/ABI/Mangling.rst
    var ptr = self.ptr
    while true {
      switch ptr.pointee {
      case 0:
        return UInt(bitPattern: ptr - self.ptr)
      case 0x01...0x17:
        // Relative symbolic reference
        ptr = ptr.advanced(by: 5)
      case 0x18...0x1f:
        // Absolute symbolic reference
        ptr = ptr.advanced(by: 1 + pointerSize)
      default:
        ptr = ptr.advanced(by: 1)
      }
    }
  }
}

private struct ValueWitnessTable {
  let ptr: UnsafeRawPointer

  var getEnumTag: @convention(c) (_ value: UnsafeRawPointer, _ metadata: UnsafeRawPointer) -> UInt32
  {
    self.ptr.advanced(by: 10 * pointerSize + 2 * 4).loadInferredType()
  }

  // This witness transforms an enum value into its associated value, in place.
  var destructiveProjectEnumData:
    @convention(c) (_ value: UnsafeMutableRawPointer, _ metadata: UnsafeRawPointer) -> Void
  {
    self.ptr.advanced(by: 11 * pointerSize + 2 * 4).loadInferredType()
  }

  // This witness transforms an associated value into its enum value, in place.
  var destructiveInjectEnumData:
    @convention(c) (_ value: UnsafeMutableRawPointer, _ tag: UInt32, _ metadata: UnsafeRawPointer)
      -> Void
  {
    self.ptr.advanced(by: 12 * pointerSize + 2 * 4).loadInferredType()
  }
}

private struct GenericArgumentVector {
  let ptr: UnsafeRawPointer
}

extension GenericArgumentVector {
  func type(atIndex i: Int) -> Any.Type {
    return ptr.load(fromByteOffset: i * pointerSize, as: Any.Type.self)
  }
}

extension UnsafeRawPointer {
  fileprivate func loadInferredType<Type>() -> Type {
    self.load(as: Type.self)
  }

  fileprivate func loadRelativePointer() -> UnsafeRawPointer? {
    let offset = Int(load(as: Int32.self))
    return offset == 0 ? nil : self + offset
  }
}

// This is the size of any Unsafe*Pointer and also the size of Int and UInt.
private let pointerSize = MemoryLayout<UnsafeRawPointer>.size

private protocol _Optional {
  associatedtype Wrapped
}
extension Optional: _Optional {}
private enum _Witness<A> {}
private protocol _AnyOptional {
  static var wrappedType: Any.Type { get }
}
extension _Witness: _AnyOptional where A: _Optional {
  static var wrappedType: Any.Type {
    A.Wrapped.self
  }
}
