# Migrating to 1.1

Learn how to migrate existing case path code to utilize the new `@CasePathable` macro and
``CaseKeyPath``s.

## Overview

CasePaths 1.1 introduces new APIs for deriving case paths that are safer, more ergonomic, more
performant, and more powerful than the existing APIs.

In past versions of the library, the primary way to derive a case path was via the form:

```
/<#enum name#>.<#case#>
```

It kind of looks like a key path with the `\` tilting the wrong way, but is actually an invocation
of a `/` prefix operator with an `Enum.case` initializer. Given just this initializer, the function
uses runtime reflection to produce a `CasePath` value.

So given an enum:

```swift
enum UserAction {
  case home(HomeAction)
}
```

One can produce a case path:

```swift
/UserAction.home
```

While the library has strived to optimize this reflection mechanism and work around bugs in the
runtime, it now offers a much better solution that is free of reflection-based code.

Deriving case paths is now a two-step process that is still mostly free of boilerplate:

1. You attach the `@CasePathable` macro to your enum:

```swift
@CasePathable
enum UserAction {
  case home(HomeAction)
}
```

2. You derive a case path using an actual key path expression:

```swift
\UserAction.Cases.home
```

This key path expression returns a ``CaseKeyPath``, which is a special kind of key path for enums
that can extract, modify, and embed the associated value of an enum case.

### Passing case key paths to APIs that take case paths

While libraries that use case paths should be updated to take ``CaseKeyPath``s directly, and should
deprecate APIs that take `CasePath`s (now ``AnyCasePath``s), you can continue to use these existing
APIs by converting case key paths to type-erased case paths via ``AnyCasePath/init(_:)``:

```swift
// Before:
action: /UserAction.home

// After:
action: AnyCasePath(\.home)
```

And when a library begins to provide APIs that take case key paths, you can pass a key path
expression directly:

```swift
action: \.home
```

### Working with case key paths

If you maintain APIs that take `CasePath` (now ``AnyCasePath``) values, you should introduce new
APIs that take ``CaseKeyPath``s instead. ``CaseKeyPath``s have all the functionality of
``AnyCasePath``s (and more), but you work with them more like regular key paths:

#### Extracting associated values

```swift
// Before:
casePath.extract(from: root)

// After:
root[case: casePath]
```

#### Embedding associated values

```swift
// Before:
casePath.embed(value)

// After:
casePath(value)
```

Case key paths can also replace an enum's existing associated value via
``CasePathable/subscript(case:)-2t4f8``:

```swift
root[case: casePath] = value
```

#### Modifying associated values

```swift
// Before:
casePath.modify(&root) {
  $0.count += 1
}

// After:
root.modify(casePath) {
  $0.count += 1
}
```
