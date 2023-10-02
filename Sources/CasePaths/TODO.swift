// NB: We support `\.self` case path via `KeyPath<Case<Root, Root>, Case<Root, Root>>`.
//     Forces `\.case.composition` to be non-optional-chained.
//     We could optional-chain via `= KeyPath<Case<Root, Root>, Case<Root, Value>?>`...
//     ...but would break `\.self` and require another discoverable name (`\.some`?) instead.

/*
 1.1.0

 * Introduce `@CasePathable` and `CasePathable`
 * Introduce `#casePath` for producing `CasePath` from case-pathable enums

 1.2.0

 * (Soft/5.9Hard-)Deprecate `CasePath` for `AnyCasePath`
 * Introduce `CaseKeyPath` as typealias to `KeyPath<AnyCasePath, AnyCasePath>`

 ...

 2.0.0

 * `CasePath` becomes official name for `CaseKeyPath`
 * Deprecate `CaseKeyPath`
 */
