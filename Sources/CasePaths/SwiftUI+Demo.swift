import SwiftUI

struct Item: Hashable, Identifiable {
  let id = UUID()
  var name: String
  var color: Color?
  var status: Status

  @CasePathable enum Status: Hashable {
    case inStock(quantity: Int)
    case outOfStock(isOnBackOrder: Bool)
  }

  enum Color: String, CaseIterable {
    case blue
    case green
    case black
    case red
    case yellow
    case white

    var toSwiftUIColor: SwiftUI.Color {
      switch self {
      case .blue: .blue
      case .green: .green
      case .black: .black
      case .red: .red
      case .yellow: .yellow
      case .white: .white
      }
    }
  }
}

struct ItemView: View {
  @Binding var item: Item

  var body: some View {
    Form {
      TextField("Name", text: self.$item.name)

      Picker("Color", selection: self.$item.color) {
        Text("None")
          .tag(Item.Color?.none)

        ForEach(Item.Color.allCases, id: \.rawValue) { color in
          Text(color.rawValue)
            .tag(Optional(color))
        }
      }

      switch self.item.status {
      case .inStock:
        // if let $quantity = self.$item.status.inStock {
        // Binding(self.$item.status.inStock).map { $quantity in
        self.$item.status.inStock.map { $quantity in
          Section(header: Text("In stock")) {
            Stepper("Quantity: \(quantity)", value: $quantity)
            Button("Mark as sold out") {
              self.item.status = .outOfStock(isOnBackOrder: false)
            }
          }
        }

      case .outOfStock:
        self.$item.status.outOfStock.map { $isOnBackOrder in
          Section(header: Text("Out of stock")) {
            Toggle("Is on back order?", isOn: $isOnBackOrder)
            Button("Is back in stock!") {
              self.item.status = .inStock(quantity: 1)
            }
          }
        }
      }
    }
  }
}

struct BindingProvider<Value, Content: View>: View {
  @State var value: Value
  @ViewBuilder let content: (Binding<Value>) -> Content
  var body: some View {
    self.content(self.$value)
  }
}

#Preview {
  BindingProvider(
    value: Item(name: "Keyboard", status: .inStock(quantity: 250))
  ) { $item in
    ItemView(item: $item)
  }
}
