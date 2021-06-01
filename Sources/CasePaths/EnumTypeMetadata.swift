
public func _extract<Root, Value>(
  _ embed: @escaping (Value) -> Root
) -> (Root) -> Value? {
  let metadataPtr = unsafeBitCast(Root.self, to: UnsafeRawPointer.self)
  let metadataKind = metadataPtr.load(as: Int.self)
  assert(metadataKind == 0x201 || metadataKind == 0x202, "'\(Root.self)' must be an enum")
  let metadata = metadataPtr.load(as: EnumMetadata.self)
  let vwtPtr = (metadataPtr - MemoryLayout<UnsafeRawPointer>.size).load(as: UnsafeRawPointer.self)
  let vwt = vwtPtr.load(as: EnumValueWitnessTable.self)
  print(Root.self, Value.self)

  var tag: UInt32?
  return { root in
    let rootTag = withUnsafePointer(to: root) { vwt.getEnumTag($0, metadataPtr) }
    guard metadata.descriptor.pointee.numPayloadCases > rootTag else { return nil }
    if let tag = tag, rootTag != tag { return nil }
    var box = unsafeBitCast(root as Any, to: AnyExistentialContainer.self)
    while box.type == Any.self {
      box = box.projectValue(vwt).load(as: AnyExistentialContainer.self)
    }
    let value = box.projectValue(vwt).load(as: Value?.self)
    guard let value = value else { return nil }
    if tag == nil {
      let newRoot = embed(value)
      let newRootTag = withUnsafePointer(to: newRoot) { vwt.getEnumTag($0, metadataPtr) }
      tag = newRootTag
      guard newRootTag == rootTag else { return nil }
    }
    return value
  }
}

public func _extract<Root>(_ root: Root) -> (Root) -> Void? {
  let metadataPtr = unsafeBitCast(Root.self, to: UnsafeRawPointer.self)
  let metadataKind = metadataPtr.load(as: Int.self)
  assert(metadataKind == 0x201 || metadataKind == 0x202, "'\(Root.self)' must be an enum")
  let metadata = metadataPtr.load(as: EnumMetadata.self)
  let vwtPtr = (metadataPtr - MemoryLayout<UnsafeRawPointer>.size).load(as: UnsafeRawPointer.self)
  let vwt = vwtPtr.load(as: EnumValueWitnessTable.self)

  let tag = withUnsafePointer(to: root) { vwt.getEnumTag($0, metadataPtr) }
  assert(
    tag >= metadata.descriptor.pointee.numPayloadCases,
    "'\(root)' must not contain associated values"
  )

  return { root in
    let rootTag = withUnsafePointer(to: root) { vwt.getEnumTag($0, metadataPtr) }
    return tag == rootTag ? () : nil
  }
}

private struct EnumMetadata {
  let kind: Int
  let descriptor: UnsafePointer<EnumDescriptor>
}

private struct EnumDescriptor {
  let flags, p1, p2, p3, p4: Int32
  let numPayloadCasesAndPayloadSizeOffset: Int32
  let numEmptyCases: Int32
  var numPayloadCases: Int32 { self.numPayloadCasesAndPayloadSizeOffset & 0xFFFFFF }
}

private struct EnumValueWitnessTable {
  let p1, p2, p3, p4, p5, p6, p7, p8: UnsafeRawPointer
  let size, stride: Int
  let flags, extraInhabitantCount: UInt32
  let getEnumTag: @convention(c) (_ value: UnsafeRawPointer, _ metadata: UnsafeRawPointer) -> UInt32
  let p9, p10: UnsafeRawPointer
}

private struct HeapObject {
  let type: Any.Type
  let refCount: UInt64
}

private struct AnyExistentialContainer {
  let data: (Int, Int, Int) = (0, 0, 0)
  let type: Any.Type

  public mutating func projectValue(_ vwt: EnumValueWitnessTable) -> UnsafeRawPointer {
    let isValueInline = vwt.flags & 0x020000 == 0
    guard !isValueInline else { return withUnsafePointer(to: &self, UnsafeRawPointer.init) }

    let alignMask = vwt.flags & 0xFF
    let heapObjSize = UInt32(MemoryLayout<HeapObject>.size)
    let byteOffset = (heapObjSize + alignMask) & ~alignMask
    let bytePtr = withUnsafePointer(to: &self) {
      $0.withMemoryRebound(to: UnsafePointer<HeapObject>.self, capacity: 1) {
        UnsafeRawPointer($0.pointee)
      }
    }

    return bytePtr + Int(byteOffset)
  }
}

