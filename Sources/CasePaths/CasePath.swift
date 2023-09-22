import Foundation
import XCTestDynamicOverlay

/// A path that supports embedding a value in a root and attempting to extract a root's embedded
/// value.
///
/// This type defines key path-like semantics for enum cases.
public struct CasePath<Root, Value> {
  private let _embed: (Value) -> Root
  private let _extract: (Root) -> Value?
  let keyPaths: [AnyKeyPath]?

  init(
    embed: @escaping (Value) -> Root,
    extract: @escaping (Root) -> Value?,
    keyPaths: [AnyKeyPath]?
  ) {
    self._embed = embed
    self._extract = extract
    self.keyPaths = keyPaths
  }

  /// Creates a case path with a pair of functions.
  ///
  /// - Parameters:
  ///   - embed: A function that always succeeds in embedding a value in a root.
  ///   - extract: A function that can optionally fail in extracting a value from a root.
  @available(
    iOS, deprecated: 9999, message: "Use '#casePath' with a '@CasePathable' enum instead"
  )
  @available(
    macOS, deprecated: 9999, message: "Use '#casePath' with a '@CasePathable' enum instead"
  )
  @available(
    tvOS, deprecated: 9999, message: "Use '#casePath' with a '@CasePathable' enum instead"
  )
  @available(
    watchOS, deprecated: 9999, message: "Use '#casePath' with a '@CasePathable' enum instead"
  )
  public init(
    embed: @escaping (Value) -> Root,
    extract: @escaping (Root) -> Value?
  ) {
    self.init(
      embed: {
        lock.lock()
        defer { lock.unlock() }
        return embed($0)
      },
      extract: {
        lock.lock()
        defer { lock.unlock() }
        return extract($0)
      },
      keyPaths: nil
    )
  }

  public static func _$init(
    embed: @escaping (Value) -> Root,
    extract: @escaping (Root) -> Value?,
    keyPath: KeyPath<Root, Value?>
  ) -> Self where Root: CasePathable {
    Self(
      embed: embed,
      extract: extract,
      keyPaths: [keyPath]
    )
  }

  /// Returns a root by embedding a value.
  ///
  /// - Parameter value: A value to embed.
  /// - Returns: A root that embeds `value`.
  public func embed(_ value: Value) -> Root {
    self._embed(value)
  }

  /// Attempts to extract a value from a root.
  ///
  /// - Parameter root: A root to extract from.
  /// - Returns: A value if it can be extracted from the given root, otherwise `nil`.
  public func extract(from root: Root) -> Value? {
    self._extract(root)
  }

  /// Attempts to modify a value in a root.
  ///
  /// - Parameters:
  ///   - root: A root to modify if the case path matches.
  ///   - body: A closure that can mutate the case's associated value. If the closure throws, the root
  ///     will be left unmodified.
  /// - Returns: The return value, if any, of the body closure.
  public func modify<Result>(
    _ root: inout Root,
    _ body: (inout Value) throws -> Result
  ) throws -> Result {
    guard var value = self.extract(from: root) else { throw ExtractionFailed() }
    let result = try body(&value)
    root = self.embed(value)
    return result
  }

  /// Returns a new case path created by appending the given case path to this one.
  ///
  /// Use this method to extend this case path to the value type of another case path.
  ///
  /// - Parameter path: The case path to append.
  /// - Returns: A case path from the root of this case path to the value type of `path`.
  public func appending<AppendedValue>(
    path: CasePath<Value, AppendedValue>
  ) -> CasePath<Root, AppendedValue> {
    CasePath<Root, AppendedValue>(
      embed: { self.embed(path.embed($0)) },
      extract: { self.extract(from: $0).flatMap(path.extract) },
      keyPaths: self.keyPaths.flatMap { keyPaths in path.keyPaths.map { keyPaths + $0 } }
    )
  }
}

struct ExtractionFailed: Error {}

#if canImport(_Concurrency) && compiler(>=5.5.2)
  extension CasePath: @unchecked Sendable {}
#endif

extension CasePath: CustomDebugStringConvertible {
  public var debugDescription: String {
    if let keyPaths = self.keyPaths {
      if keyPaths.isEmpty {
        return "\\\(Root.self).self"
      } else if #available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *) {
        return "\\\(Root.self).\(keyPaths.map(\.componentName).joined(separator: "?."))"
      }
    }
    return "CasePath<\(Root.self), \(Value.self)>"
  }
}

@available(macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4, *)
extension AnyKeyPath {
  fileprivate var componentName: String {
    String(self.debugDescription.dropFirst("\\\(Self.rootType).".count))
  }
}

private let lock = NSRecursiveLock()
