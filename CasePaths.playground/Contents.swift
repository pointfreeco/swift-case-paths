import CasePaths

enum AppState {
  case loggedIn(LoggedInState)
  case loggedOut(LoggedOutState)
}

struct LoggedInState {}
struct LoggedOutState {}

let loggedInCasePath = CasePath<AppState, LoggedInState>(
  embed: AppState.loggedIn,
  extract: { appState in
    guard case let .loggedIn(state) = appState
    else { return nil }
    return state
  }
)

\String.count

/AppState.loggedIn

enum Foo {
  case bar(a: Int, b: Int)
  case bar(a: Int)
  case baz(Int)
}

let mirror = Mirror(reflecting: Foo.bar(a: 1, b: 2))
mirror.children.first!
