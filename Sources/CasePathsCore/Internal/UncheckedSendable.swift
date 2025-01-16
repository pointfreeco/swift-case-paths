@propertyWrapper
package struct UncheckedSendable<Value>: @unchecked Sendable {
  package var wrappedValue: Value
  package init(wrappedValue value: Value) {
    self.wrappedValue = value
  }
  package var projectedValue: Self { self }
}
