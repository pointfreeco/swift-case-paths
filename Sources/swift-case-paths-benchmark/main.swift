import Benchmark
import CasePaths

enum Enum {
  case associatedValue(Int)
}

let manual = CasePath(
  embed: Enum.associatedValue,
  extract: {
    guard case let .associatedValue(value) = $0 else { return nil }
    return value
  }
)

let reflection = /Enum.associatedValue

let enumCase = Enum.associatedValue(42)

benchmark("Manual") {
  precondition(manual.extract(from: enumCase) == 42)
}

benchmark("Reflection") {
  precondition(reflection.extract(from: enumCase) == 42)
}

Benchmark.main()
