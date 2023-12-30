@inline(__always)
func doNotOptimizeAway<T>(_ x: T) {
  @_optimize(none)
  func assumePointeeIsRead(_ x: UnsafeRawPointer) {}

  withUnsafePointer(to: x) { assumePointeeIsRead($0) }
}
