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
SwiftUI [environment][environment-property-wrapper-docs].

Unfortunately, no such structure exists for enum cases.

``` swift
enum UserAction {
  case home(HomeAction)
  case settings(SettingsAction)
}

\UserAction.home  // 🛑
```

> 🛑 key path cannot refer to static member 'home'

And so it's not possible to write generic code that can zoom in on and propagate changes to a
particular case.

[key-path-docs]: https://developer.apple.com/documentation/swift/swift_standard_library/key-path_expressions
[dynamic-member-lookup-proposal]: https://github.com/apple/swift-evolution/blob/master/proposals/0252-keypath-dynamic-member-lookup.md
[binding-dynamic-member-lookup-docs]: https://developer.apple.com/documentation/swiftui/bindable/subscript(dynamicmember:)
[environment-property-wrapper-docs]: https://developer.apple.com/documentation/swiftui/scene/environment(_:_:)
[combine-publisher-assign-docs]: https://developer.apple.com/documentation/combine/publisher/assign(to:on:)

## Introducing: case paths

This library bridges this gap by introducing what we call "case paths": key paths for enum cases.

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

#### Extracting, embedding, and modifying values

As key paths package up the functionality of getting and setting a value on a root structure, case
paths package up the functionality of optionally extracting and modifying an associated value of a
root enumeration.

``` swift
user[keyPath: \User.name] = "Blob"
user[keyPath: \.name]  // "Blob"

userAction[keyPath: \UserAction.Cases.home] = .onAppear
userAction[keyPath: \.home]  // Optional(HomeAction.onAppear)
```

If the case doesn't match, the extraction can fail and return `nil`:

```swift
userAction[keyPath: \.settings]  // nil
```

Case paths have an additional ability, which is to embed an associated value into a brand new root:

```swift
let userActionToHome = \UserAction.Cases.home
userActionToHome(.onAppear)  // UserAction.home(.onAppear)
```

#### Composing paths

Case paths, like key paths, compose. You can dive deeper into the enumeration of an enumeration's
case using familiar dot-chaining:

``` swift
\HighScore.user.name
// WritableKeyPath<HighScore, String>

\AppAction.Cases.user.home
// CasePath<AppAction, HomeAction>
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
// CasePath<AppAction, HomeAction>
```

#### Identity paths

Case paths, also like key paths, provide an
[identity](https://github.com/apple/swift-evolution/blob/master/proposals/0227-identity-keypath.md)
path, which is useful for interacting with APIs that use key paths and case paths but you want to
work with entire structure.

``` swift
\User.self              // WritableKeyPath<User, User>
\UserAction.Cases.self  // CasePath<UserAction, UserAction>
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
userAction.home  // Optional(HomeAction.onAppear)

let userActions: [UserAction] = [.home(.onAppear), .settings(.purchaseButtonTapped)]
userActions.compactMap(\.home)  // [HomeAction.onAppear]
```

#### Dynamic case lookup

Because case key paths are bona fide key paths, they can be used in the same applications, like
dynamic member lookup. For example, we can extend SwiftUI's binding type to enum cases by extending
it with a subscript:

```swift
extension Binding {
  subscript<Member>(
    dynamicMember keyPath: CaseKeyPath<Value, Member>
  ) -> Binding<Member>? {
    guard let member = self.wrappedValue[keyPath: keyPath]
    else { return nil }
    return Binding<Member>(
      get: { self.wrappedValue ?? member },
      set: { self.wrappedValue[keyPath: keyPath] = $0 }
    )
  }
}

@CasePathable enum ItemStatus {
  case inStock(quantity: Int)
  case outOfStock(isOnBackOrder: Bool)
}

struct ItemStatusView: View {
  @State var status: ItemStatus

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

If you want to discuss this library or have a question about how to use it to solve 
a particular problem, there are a number of places you can discuss with fellow 
[Point-Free](http://www.pointfree.co) enthusiasts:

  * For long-form discussions, we recommend the
    [discussions](http://github.com/pointfreeco/swift-case-paths/discussions) tab of this repo.
  * For casual chat, we recommend the
    [Point-Free Community Slack](http://pointfree.co/slack-invite).

## Documentation

The latest documentation for CasePaths' APIs is available [here](https://pointfreeco.github.io/swift-case-paths/main/documentation/casepaths/).

## Other libraries

  * [`EnumKit`](https://github.com/gringoireDM/EnumKit) is a protocol-oriented, reflection-based
    solution to ergonomic enum access and inspired the creation of this library.

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
