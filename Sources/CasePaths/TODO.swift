// NB: We support `\.self` case path via `KeyPath<Case<Root, Root>, Case<Root, Root>>`.
//     Forces `\.case.composition` to be non-optional-chained.
//     We could optional-chain via `= KeyPath<Case<Root, Root>, Case<Root, Value>?>`...
//     ...but would break `\.self` and require another discoverable name (`\.some`?) instead.
