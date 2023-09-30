import SwiftUI


extension Binding where Value: CasePathable {
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Value.AllCasePaths, CasePath<Value, Member>>
  ) -> Binding<Member?> {
    let casePath = Value.allCasePaths[keyPath: keyPath]
    return Binding<Member?>(
      get: { self.wrappedValue[casePath: casePath] },
      set: { newValue, transaction in
        guard case casePath = self.wrappedValue, let newValue else { return }
        self.transaction(transaction).wrappedValue[casePath: casePath] = newValue
      }
    )
  }
}

// NB: Simplifies `Binding($item.inStock).map` -> `$item.inStock.map`, but is a more complex
//     implementation (internal mutable variable) and kind of feels less "correct".
//
//extension Binding where Value: CasePathable {
//  public subscript<Member>(
//    dynamicMember keyPath: KeyPath<Value.AllCasePaths, CasePath<Value, Member>>
//  ) -> Binding<Member>? {
//    let casePath = Value.allCasePaths[keyPath: keyPath]
//    guard var member = self.wrappedValue[casePath: casePath] else { return nil }
//    return Binding<Member>(
//      get: { self.wrappedValue[casePath: casePath] ?? member },
//      set: { newValue, transaction in
//        guard case casePath = self.wrappedValue else { return }
//        member = newValue
//        self.transaction(transaction).wrappedValue[casePath: casePath] = newValue
//      }
//    )
//  }
//}
