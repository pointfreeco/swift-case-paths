import SwiftUI

extension Binding where Value: CasePathable {
  public subscript<Member>(
    dynamicMember keyPath: CasePath<Value, Member>
  ) -> Binding<Member?> {
    return Binding<Member?>(
      get: { self.wrappedValue[keyPath: keyPath] },
      set: { newValue, transaction in
        guard let newValue else { return }
        self.transaction(transaction).wrappedValue[keyPath: keyPath] = newValue
      }
    )
  }
}
