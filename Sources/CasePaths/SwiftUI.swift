import SwiftUI

extension Binding where Value: CasePathable {
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Value.AllCasePaths, CasePath<Value, Member>>
  ) -> Binding<Member>? {
    let casePath = Value.allCasePaths[keyPath: keyPath]
    guard var member = self.wrappedValue[casePath: casePath] else { return nil }
    return Binding<Member>(
      get: { self.wrappedValue[casePath: casePath] ?? member },
      set: { newValue, transaction in
        guard casePath ~= self.wrappedValue else { return }
        member = newValue
        self.transaction(transaction).wrappedValue[casePath: casePath] = newValue
      }
    )
  }
}

// NB: Simpler implementation, slightly more complex (but easier to understand?) call site:
//     `Binding($item.status.inStock).map { $quantity in`
//
//extension Binding where Value: CasePathable {
//  public subscript<Member>(
//    dynamicMember keyPath: KeyPath<Value.AllCasePaths, CasePath<Value, Member>>
//  ) -> Binding<Member?> {
//    let casePath = Value.allCasePaths[keyPath: keyPath]
//    return Binding<Member?>(
//      get: { self.wrappedValue[casePath: casePath] },
//      set: { newValue, transaction in
//        guard casePath ~= self.wrappedValue, let newValue else { return }
//        self.transaction(transaction).wrappedValue[casePath: casePath] = newValue
//      }
//    )
//  }
//}
