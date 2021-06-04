import Echo

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
public func extract<Root, Value>(case embed: @escaping (Value) -> Root, from root: Root) -> Value? {
  extract(embed)(root)
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
public func extract<Root, Value>(_ embed: @escaping (Value) -> Root) -> (Root) -> (Value?) {
  let metadata = reflectEnum(Root.self)!

  var tag: UInt32?
  return { root in
    let rootTag = withUnsafePointer(to: root) { metadata.enumVwt.getEnumTag(for: $0) }
    if let tag = tag, rootTag != tag { return nil }

    let field = metadata.descriptor.fields.records[Int(rootTag)]
    let type = metadata.type(of: field.mangledTypeName)

    guard type != nil || field.flags.isIndirectCase else {
      return nil
    }

    let nativeObject = KnownMetadata.Builtin.nativeObject
    let payloadMetadata = field.flags.isIndirectCase ? nativeObject : reflect(type!)
    let pair = swift_allocBox(for: payloadMetadata)

    var container = container(for: root)
    var opaqueValue = container.projectValue()

    metadata.enumVwt
      .destructiveProjectEnumData(for: UnsafeMutableRawPointer(mutating: opaqueValue))
    payloadMetadata.vwt.initializeWithCopy(
      UnsafeMutableRawPointer(mutating: pair.buffer), UnsafeMutableRawPointer(mutating: opaqueValue)
    )
    metadata.enumVwt
      .destructiveInjectEnumTag(for: UnsafeMutableRawPointer(mutating: opaqueValue), tag: rootTag)

    opaqueValue = pair.buffer

    if field.flags.isIndirectCase {
      let owner = UnsafePointer<UnsafePointer<HeapObject>>(opaqueValue._rawValue).pointee
      opaqueValue = swift_projectBox(for: owner)
    }

    var valueContainer = AnyExistentialContainer(metadata: payloadMetadata)
    let buffer = payloadMetadata.allocateBoxForExistential(in: &valueContainer)
    payloadMetadata.vwt.initializeWithCopy(
      UnsafeMutableRawPointer(mutating: buffer), UnsafeMutableRawPointer(mutating: opaqueValue)
    )

    swift_release(pair.heapObj)

    let value: Value?
    if payloadMetadata.type == Any.self && Value.self != Any.self {
      value = valueContainer.projectValue().load(as: Any.self) as? Value
    } else {
      if payloadMetadata.type != Value.self {
        switch (payloadMetadata, reflect(Value.self)) {
        // Normalize labeled payloads (`(Int, Int)` vs. `(x: Int, y: Int)`)
        case let (fieldType as TupleMetadata, valueType as TupleMetadata):
          guard
            valueType.numElements == fieldType.numElements,
            zip(valueType.elements, fieldType.elements).allSatisfy({ $0.type == $1.type })
          else { return nil }

        // Normalize labeled payload (`(id: Int)` vs. `Int`)
        case let (fieldType as TupleMetadata, _):
          guard
            fieldType.numElements == 1,
            fieldType.elements[0].type == Value.self
          else { return nil }

        // Handle indirect payloads
        case (is OpaqueMetadata, _):
          break

        // Handle protocol conformances (`Error as? MyError`)
        case let (fieldType as ExistentialMetadata, valueType as TypeMetadata):
          guard fieldType.type == Any.self || valueType.conformances.contains(
            where: { conformance in fieldType.protocols.contains(conformance.protocol) }
          )
          else { return nil }

//        case let (valueType, fieldType):
        default:
          return nil
        }
      }
      value = valueContainer.projectValue().load(as: Value.self)
    }
    guard let value = value else { return nil }

    if tag == nil {
      let newRoot = embed(value)
      let newRootTag = withUnsafePointer(to: newRoot) { metadata.enumVwt.getEnumTag(for: $0) }
      tag = newRootTag
      guard newRootTag == rootTag else { return nil }
    }

    return value
  }
}

@_silgen_name("swift_projectBox")
public func swift_projectBox(for heapObj: UnsafePointer<HeapObject>) -> UnsafeRawPointer

@_silgen_name("swift_projectBox")
public func swift_release(_ heapObj: UnsafePointer<HeapObject>)
