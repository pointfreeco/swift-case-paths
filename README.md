# 🧰 CasePaths

[![CI](https://github.com/pointfreeco/swift-case-paths/workflows/CI/badge.svg)](https://actions-badge.atrox.dev/pointfreeco/swift-case-paths/goto)
[![Slack](https://img.shields.io/badge/slack-chat-informational.svg?label=Slack&logo=slack)](http://pointfree.co/slack-invite)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-case-paths%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-case-paths)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-case-paths%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-case-paths)

Case paths extends the key path hierarchy to enum cases.

## Motivation

Swift endows every struct and class property with a [key path][key-path-docs].

[key-path-docs]: https://developer.apple.com/documentation/swift/swift_standard_library/key-path_expressions

``` swift
struct User {
  let id: Int
  var name: String
}

\User.id    // KeyPath<User, Int>
\User.name  // WritableKeyPath<User, String>
```

This is compiler-generated code that can be used to abstractly zoom in on part of a structure,
inspect and even change it, all while propagating those changes to the structure's whole. They are
the silent partner of many modern Swift APIs powered by
[dynamic member lookup][dynamic-member-lookup-proposal], like SwiftUI
[bindings][binding-dynamic-member-lookup-docs], but also make more direct appearances, like in the
SwiftUI [environment][environment-property-wrapper-docs] and [unsafe mutable pointers][pointee].

[pointee]: https://developer.apple.com/documentation/swift/unsafemutablepointer/pointer(to:)-8veyb

Unfortunately, no such structure exists for enum cases.

``` swift
enum UserAction {
  case home(HomeAction)
  case settings(SettingsAction)
}

\UserAction.home  // 🛑
```

> 🛑 key path cannot refer to static member 'home'

And so it's not possible to write generic code that can zoom in and modify the data of a particular
case in the enum.

[key-path-docs]: https://developer.apple.com/documentation/swift/swift_standard_library/key-path_expressions
[dynamic-member-lookup-proposal]: https://github.com/apple/swift-evolution/blob/master/proposals/0252-keypath-dynamic-member-lookup.md
[binding-dynamic-member-lookup-docs]: https://developer.apple.com/documentation/swiftui/bindable/subscript(dynamicmember:)
[environment-property-wrapper-docs]: https://developer.apple.com/documentation/swiftui/scene/environment(_:_:)
[combine-publisher-assign-docs]: https://developer.apple.com/documentation/combine/publisher/assign(to:on:)

## Using case paths in libraries

By far the most common use of case paths is as a tool inside a library that is distributed to other
developers. Case paths are used in the [Composable Architecture][tca-gh],
[SwiftUI Navigation][sui-nav-gh], [Parsing][parsers-gh], and many other libraries.

[tca-gh]: http://github.com/pointfreeco/swift-composable-architecture
[sui-nav-gh]: http://github.com/pointfreeco/swiftui-navigation
[parsers-gh]: http://github.com/pointfreeco/swift-parsing

If you maintain a library where you expect your users to model their domains with enums, then
providing case path tools to them can help them break their domains into smaller units. For
example, consider the `Binding` type provided by SwiftUI:

```swift
struct Binding<Value> {
  let get: () -> Value
  let set: (Value) -> Void
}
```

Through the power of [dynamic member lookup][dynamic-member-lookup-proposal] we are able to support
dot-chaining syntax for deriving new bindings to members of values:

```swift
@dynamicMemberLookup
struct Binding<Value> {
  …
  subscript<Member>(dynamicMember keyPath: WritableKeyPath<Value, Member>) -> Binding<Member> {
    Binding<Member>(
      get: { self.get()[keyPath: keyPath] },
      set: { 
        var value = self.get()
        value[keyPath: keyPath] = $0
        self.set(value)
      }
    )
  }
}
```

If you had a binding of a user, you could simply append `.name` to that binding to immediately
derive a binding to the user's name:

```swift
let user: Binding<User> = // ...
let name: Binding<String> = user.name
```

However, there are no such affordances for enums:

```swift
enum Destination {
  case home(HomeState)
  case settings(SettingsState)
}
let destination: Binding<Destination> = // ...
destination.home      // 🛑
destination.settings  // 🛑
```

It is not possible to derive a binding to just the `home` case of a destination binding by using
simple dot-chaining syntax.

However, if SwiftUI used this CasePaths library, then they could provide this tool quite easily.
They could provide an additional `dynamicMember` subscript that uses a `CaseKeyPath`, which is a
key path that singles out a case of an enum, and use that to derive a binding to a particular
case of an enum:

```swift
import CasePaths

extension Binding {
  public subscript<Case>(dynamicMember keyPath: CaseKeyPath<Value, Case>) -> Binding<Case>?
  where Value: CasePathable {
    Binding<Case>(
      unwrapping: Binding<Case?>(
        get: { self.wrappedValue[case: keyPath] },
        set: { newValue, transaction in
          guard let newValue else { return }
          self.transaction(transaction).wrappedValue[case: keyPath] = newValue
        }
      )
    )
  }
}
```

With that defined, one can annotate their enum with the `@CasePathable` macro and then immediately
use dot-chaining to derive a binding of a case from a binding of an enum:

```swift
@CasePathable
enum Destination {
  case home(HomeState)
  case settings(SettingsState)
}
let destination: Binding<Destination> = // ...
destination.home      // Binding<HomeState>?
destination.settings  // Binding<SettingsState>?
```

This is an example of how libraries can provide tools for their users to embrace enums without
losing out on the ergonomics of structs. 

## Basics of case paths

While library tooling is the biggest use case for using this library, there are some ways that you
can use case paths in first-party code too. The library bridges the gap between structs and enums by
introducing what we call "case paths": key paths for enum cases.

Case paths can be enabled for an enum using the `@CasePathable` macro:

```swift
@CasePathable
enum UserAction {
  case home(HomeAction)
  case settings(SettingsAction)
}
```

And they can be produced from a "case-pathable" enum through its `Cases` namespace:

```swift
\UserAction.Cases.home      // CaseKeyPath<UserAction, HomeAction>
\UserAction.Cases.settings  // CaseKeyPath<UserAction, SettingsAction>
```

And like any key path, they can be abbreviated when the enum type can be inferred:

```swift
\.home as CaseKeyPath<UserAction, HomeAction>
\.settings as CaseKeyPath<UserAction, SettingsAction>
```

### Case paths vs. key paths

#### Extracting, embedding, modifying, and testing values

As key paths package up the functionality of getting and setting a value on a root structure, case
paths package up the functionality of optionally extracting and modifying an associated value of a
root enumeration.

``` swift
user[keyPath: \User.name] = "Blob"
user[keyPath: \.name]  // "Blob"

userAction[case: \UserAction.Cases.home] = .onAppear
userAction[case: \.home]  // Optional(HomeAction.onAppear)
```

If the case doesn't match, the extraction can fail and return `nil`:

```swift
userAction[case: \.settings]  // nil
```

Case paths have an additional ability, which is to embed an associated value into a brand new root:

```swift
let userActionToHome = \UserAction.Cases.home
userActionToHome(.onAppear)  // UserAction.home(.onAppear)
```

Cases can be tested using the `is` method on case-pathable enums:

```swift
userAction.is(\.home)      // true
userAction.is(\.settings)  // false

let actions: [UserAction] = […]
let homeActionsCount = actions.count(where: { $0.is(\.home) })
```

And their associated values can be mutated in place using the `modify` method:

```swift
var result = Result<String, Error>.success("Blob")
result.modify(\.success) {
  $0 += ", Jr."
}
result  // Result.success("Blob, Jr.")
```

#### Composing paths

Case paths, like key paths, compose. You can dive deeper into the enumeration of an enumeration's
case using familiar dot-chaining:

``` swift
\HighScore.user.name
// WritableKeyPath<HighScore, String>

\AppAction.Cases.user.home
// CaseKeyPath<AppAction, HomeAction>
```

Or you can append them together:

```swift
let highScoreToUser = \HighScore.user
let userToName = \User.name
let highScoreToUserName = highScoreToUser.append(path: userToName)
// WritableKeyPath<HighScore, String>

let appActionToUser = \AppAction.Cases.user
let userActionToHome = \UserAction.Cases.home
let appActionToHome = appActionToUser.append(path: userActionToHome)
// CaseKeyPath<AppAction, HomeAction>
```

#### Identity paths

Case paths, also like key paths, provide an
[identity](https://github.com/apple/swift-evolution/blob/master/proposals/0227-identity-keypath.md)
path, which is useful for interacting with APIs that use key paths and case paths but you want to
work with entire structure.

``` swift
\User.self              // WritableKeyPath<User, User>
\UserAction.Cases.self  // CaseKeyPath<UserAction, UserAction>
```

#### Property access

Since Swift 5.2, key path expressions can be passed directly to methods like `map`. Case-pathable
enums that are annotated with dynamic member lookup enable property access and key path expressions
for each case.

```swift
@CasePathable
@dynamicMemberLookup
enum UserAction {
  case home(HomeAction)
  case settings(SettingsAction)
}

let userAction: UserAction = .home(.onAppear)
userAction.home      // Optional(HomeAction.onAppear)
userAction.settings  // nil

let userActions: [UserAction] = [.home(.onAppear), .settings(.purchaseButtonTapped)]
userActions.compactMap(\.home)  // [HomeAction.onAppear]
```

#### Dynamic case lookup

Because case key paths are bona fide key paths under the hood, they can be used in the same
applications, like dynamic member lookup. For example, we can extend SwiftUI's binding type to enum
cases by extending it with a subscript:

```swift
extension Binding {
  subscript<Member>(
    dynamicMember keyPath: CaseKeyPath<Value, Member>
  ) -> Binding<Member>? {
    guard let member = self.wrappedValue[case: keyPath]
    else { return nil }
    return Binding<Member>(
      get: { self.wrappedValue[case: keyPath] ?? member },
      set: { self.wrappedValue[case: keyPath] = $0 }
    )
  }
}

@CasePathable enum ItemStatus {
  case inStock(quantity: Int)
  case outOfStock(isOnBackOrder: Bool)
}

struct ItemStatusView: View {
  @Binding var status: ItemStatus

  var body: some View {
    switch self.status {
    case .inStock:
      self.$status.inStock.map { $quantity in
        Section {
          Stepper("Quantity: \(quantity)", value: $quantity)
          Button("Mark as sold out") {
            self.item.status = .outOfStock(isOnBackOrder: false)
          }
        } header: {
          Text("In stock")
        }
      }
    case .outOfStock:
      self.$status.outOfStock.map { $isOnBackOrder in
        Section {
          Toggle("Is on back order?", isOn: $isOnBackOrder)
          Button("Is back in stock!") {
            self.item.status = .inStock(quantity: 1)
          }
        } header: {
          Text("Out of stock")
        }
      }
    }
  }
}
```

> **Note**
> The above is a simplified version of the subscript that ships in our
> [SwiftUINavigation](https://github.com/pointfreeco/swiftui-navigation) library.

#### Computed paths

Key paths are created for every property, even computed ones, so what is the equivalent for case
paths? Well, "computed" case paths can be created by extending the case-pathable enum's
`AllCasePaths` type with properties that implement the `embed` and `extract` functionality of a
custom case:

```swift
@CasePathable
enum Authentication {
  case authenticated(accessToken: String)
  case unauthenticated
}

extension Authentication.AllCasePaths {
  var encrypted: AnyCasePath<Authentication, String> {
    AnyCasePath(
      embed: { decryptedToken in
        .authenticated(token: encrypt(decryptedToken))
      },
      extract: { authentication in
        guard
          case let .authenticated(encryptedToken) = authentication,
          let decryptedToken = decrypt(token)
        else { return nil }
        return decryptedToken
      }
    )
  }
}

\Authentication.Cases.encrypted
// CaseKeyPath<Authentication, String>
```

## Case studies

  * [**SwiftUINavigation**](https://github.com/pointfreeco/swiftui-navigation) uses case paths to
    power SwiftUI bindings, including navigation, with enums.

  * [**The Composable Architecture**](https://github.com/pointfreeco/swift-composable-architecture)
    allows you to break large features down into smaller ones that can be glued together user key
    paths and case paths.

  * [**Parsing**](https://github.com/pointfreeco/swift-parsing) uses case paths to turn unstructured
    data into enums and back again.

Do you have a project that uses case paths that you'd like to share? Please
[open a PR](https://github.com/pointfreeco/swift-case-paths/edit/main/README.md) with a link to it!

## Community

If you want to discuss this library or have a question about how to use it to solve a particular
problem, there are a number of places you can discuss with fellow
[Point-Free](http://www.pointfree.co) enthusiasts:

  * For long-form discussions, we recommend the
    [discussions](http://github.com/pointfreeco/swift-case-paths/discussions) tab of this repo.
  * For casual chat, we recommend the
    [Point-Free Community Slack](http://pointfree.co/slack-invite).

## Documentation

The latest documentation for CasePaths' APIs is available
[here](https://swiftpackageindex.com/pointfreeco/swift-case-paths/main/documentation/casepaths).

## Credit and thanks

Special thanks to [Giuseppe Lanza](https://github.com/gringoireDM), whose
[EnumKit](https://github.com/gringoireDM/EnumKit) inspired the original, reflection-based solution
this library used to power case paths.

## Interested in learning more?

These concepts (and more) are explored thoroughly in [Point-Free](https://www.pointfree.co), a video
series exploring functional programming and Swift hosted by
[Brandon Williams](https://github.com/mbrandonw) and
[Stephen Celis](https://github.com/stephencelis).

The design of this library was explored in the following [Point-Free](https://www.pointfree.co)
episodes:

  * [Episode 87](https://www.pointfree.co/episodes/ep87-the-case-for-case-paths-introduction): The
    Case for Case Paths: Introduction
  * [Episode 88](https://www.pointfree.co/episodes/ep88-the-case-for-case-paths-properties): The
    Case for Case Paths: Properties
  * [Episode 89](https://www.pointfree.co/episodes/ep89-case-paths-for-free): Case Paths for Free

<a href="https://www.pointfree.co/episodes/ep87-the-case-for-case-paths-introduction">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/episodes/0087.jpeg" width="480">
</a>

## License

All modules are released under the MIT license. See [LICENSE](LICENSE) for details.
