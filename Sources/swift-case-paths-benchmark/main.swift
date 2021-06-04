import Benchmark
import CasePaths

enum Foo {
  case bar
  case baz(Int)
  case fizzBuzz(FizzBuzz)
  case neverEver(NeverEver)

  enum Baz {
    case num(Int)
  }
  struct FizzBuzz {
    let nums: [Int]
  }
  enum NeverEver {}
}

let baz = Foo.baz(42)
let fizzBuzz = Foo.fizzBuzz(.init(nums: Array(1...100_000)))

let manual = CasePath<Foo, Int>(
  embed: Foo.baz,
  extract: {
    guard case let .baz(n) = $0 else { return nil }
    return n
  }
)

benchmark("manual extract: success") {
  precondition(manual.extract(from: baz) == 42)
}
benchmark("manual extract: failure") {
  precondition(manual.extract(from: fizzBuzz) == nil)
}

let reflection1: CasePath<Foo, Int> = /Foo.baz
benchmark("reflection extract: success") {
  precondition(reflection1.extract(from: baz) == 42)
}
let reflection2: CasePath<Foo, Int> = /Foo.baz
benchmark("reflection extract: failure") {
  precondition(reflection2.extract(from: fizzBuzz) == nil)
}

Benchmark.main()
