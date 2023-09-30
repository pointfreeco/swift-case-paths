import SwiftUI

// TODO: Better name? `CasePathLookup`?
// TODO: Should this alias be named `CasePath` and the `embed`/`extract` pair be something else?
//       Much bigger change, but if we rename `AllCasePaths`, we could potentially get rid of
//       `#casePath(\Enum.ok)` and `#casePath(\.ok)` and simply have `\Enum.Cases.ok` and `\.ok`...
public typealias DynamicCasePath<Root: CasePathable, Value> = KeyPath<
  Root.AllCasePaths, CasePath<Root, Value>
>

extension Binding where Value: CasePathable {
  public subscript<Member>(
    dynamicMember keyPath: DynamicCasePath<Value, Member>
  ) -> Binding<Member?> {
    return Binding<Member?>(
      get: { self.wrappedValue[keyPath: keyPath] },
      set: { newValue, transaction in
        guard let newValue else { return }
        self.transaction(transaction).wrappedValue[keyPath: keyPath] = newValue
      }
    )
  }

  // TODO: Should/could this be simplified with a macro expansion?
  //
  // @dynamicCaseLookup
  // subscript<Case>(dynamicMember casePath: CasePath<Value, Case>) -> Binding<Case?> {
  //
  // public subscript<Member>(
  //   dynamicMember keyPath: KeyPath<Value.AllCasePaths, CasePath<Value, Member>>
  // ) -> Binding<Member?> {
  //   let casePath = Value.allCasePaths[keyPath: keyPath]
  //   return Binding<Member?>(
  //     get: { self.wrappedValue[casePath: casePath] },
  //     set: { newValue, transaction in
  //       guard case casePath = self.wrappedValue, let newValue else { return }
  //       self.transaction(transaction).wrappedValue[casePath: casePath] = newValue
  //     }
  //   )
  // }
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
