@propertyWrapper
struct UncheckedSendable<Value>: @unchecked Sendable {
  var wrappedValue: Value
  init(wrappedValue value: Value) {
    self.wrappedValue = value
  }
  var projectedValue: Self { self }
}
