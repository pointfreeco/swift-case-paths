#if canImport(SwiftUI)
  import SwiftUI

  extension Binding where Value: CasePathable {
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
