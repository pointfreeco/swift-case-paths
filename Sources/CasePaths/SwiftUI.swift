#if canImport(SwiftUI)
  import SwiftUI

  extension Binding where Value: CasePathable {
    /// Returns a binding to the associated value of a given case key path.
    ///
    /// - Parameter keyPath: A case key path to a specific associated value.
    /// - Returns: A new binding.
    public subscript<Member>(
      dynamicMember keyPath: CaseKeyPath<Value, Member>
    ) -> Binding<Member?> {
      Binding<Member?>(
        get: { self.wrappedValue[keyPath: keyPath] },
        set: { newValue, transaction in
          guard let newValue else { return }
          self.transaction(transaction).wrappedValue[keyPath: keyPath] = newValue
        }
      )
    }
  }
#endif
