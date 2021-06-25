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


private func enumTag<Case>(_ `case`: Case) -> UInt32? {
  let metadataPtr = unsafeBitCast(type(of: `case`), to: UnsafeRawPointer.self)
  let kind = metadataPtr.load(as: Int.self)
  let isEnumOrOptional = kind == 0x201 || kind == 0x202
  guard isEnumOrOptional else { return nil }
  let vwtPtr = (metadataPtr - MemoryLayout<UnsafeRawPointer>.size).load(as: UnsafeRawPointer.self)
  let vwt = vwtPtr.load(as: EnumValueWitnessTable.self)
  return withUnsafePointer(to: `case`) { vwt.getEnumTag($0, metadataPtr) }
}

private struct EnumValueWitnessTable {
  let f1, f2, f3, f4, f5, f6, f7, f8: UnsafeRawPointer
  let f9, f10: Int
  let f11, f12: UInt32
  let getEnumTag: @convention(c) (UnsafeRawPointer, UnsafeRawPointer) -> UInt32
  let f13, f14: UnsafeRawPointer
}

enumTag(Foo.bar(a: 3, b: 4))
enumTag(Foo.bar(a: 100))
enumTag(Foo.baz(100))
