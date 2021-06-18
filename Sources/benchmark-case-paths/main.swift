import Benchmark
import CasePaths

enum Foo {
  case bar(Int)
  case baz(Int)
}

let bar = Foo.bar(42)
let baz = Foo.baz(1729)

let manual = CasePath<Foo, Int>(
  embed: Foo.bar,
  extract: {
    guard case let .bar(n) = $0 else { return nil }
    return n
  }
)

benchmark("manual extract: success") {
  precondition(manual.extract(from: bar) == 42)
}
benchmark("manual extract: failure") {
  precondition(manual.extract(from: baz) == nil)
}

let reflection1: CasePath<Foo, Int> = /Foo.bar
benchmark("reflection extract: success") {
  precondition(reflection1.extract(from: bar) == 42)
}
let reflection2: CasePath<Foo, Int> = /Foo.bar
benchmark("reflection extract: failure") {
  precondition(reflection2.extract(from: baz) == nil)
}
benchmark("reflection extract: failure after success") {
  precondition(reflection1.extract(from: baz) == nil)
}

Benchmark.main()
