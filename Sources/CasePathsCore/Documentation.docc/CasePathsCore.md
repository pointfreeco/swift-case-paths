# ``CasePathsCore``

Case paths bring the power and ergonomics of key paths to enums.

## Overview

This module contains the core functionality of the Case Paths library, minus the `@CasePathable`
macro, and is automatically imported when you `import CasePaths`

See the [`CasePaths`](../casepaths) module for information about the `@CasePathable` macro and
other non-core functionality.

To use Case paths without relying on the `@CasePathable` macro import `CasePathsCore` and manually conform your type to the `CasePathable` protocol.

For example the `Result` type is extended to be case-pathable with the following extension:

```swift
import CasePathsCore

extension Result: CasePathable {
  public struct AllCasePaths {
    var success: AnyCasePath<Result, Success> {
      AnyCasePath(
        embed: { .success($0) },
        extract: {
          guard case let .success(value) = $0 else { return nil }
          return value
        }
      )
    }

    var failure: AnyCasePath<Result, Failure> {
      AnyCasePath(
        embed: { .failure($0) },
        extract: {
          guard case let .failure(value) = $0 else { return nil }
          return value
        }
      )
    }
  }

  public static var allCasePaths: AllCasePaths { AllCasePaths() }
}
```

## Topics

### Creating case paths

- ``CasePathable``
- ``CaseKeyPath``

### Swift support

- ``Swift/Optional``
- ``Swift/Result``
- ``Swift/Never``

### Migration guides

- <doc:MigrationGuides>
