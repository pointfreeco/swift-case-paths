public protocol AnyCasePath: CustomDebugStringConvertible {
  static var rootType: Any.Type { get }
  static var valueType: Any.Type { get }
}

public protocol PartialCasePath<Root>: AnyCasePath {
  associatedtype Root
}

extension CasePath: PartialCasePath {
  public static var rootType: Any.Type { Root.self }
  public static var valueType: Any.Type { Value.self }
}

extension CasePath: CustomDebugStringConvertible {
  public var debugDescription: String {
    if self.keyPaths.isEmpty {
      "\\\(Root.self).self"
    } else if #available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *) {
      "\\\(Root.self).\(self.keyPaths.map(\.componentName).joined(separator: "?."))"
    } else {
      "CasePath<\(Root.self), \(Value.self)>"
    }
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
fileprivate extension AnyKeyPath {
  var componentName: String {
    String(self.debugDescription.dropFirst("\\\(Self.rootType).".count))
  }
}
