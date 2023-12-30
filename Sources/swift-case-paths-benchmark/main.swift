import Benchmark
import CasePaths

benchmark("Append Case Key Path (2): Embed") {
  let ckp: CaseKeyPath<Result<Int?, any Error>, Int> = \.success.some
  doNotOptimizeAway(ckp(42))
}
benchmark("Append Case Key Path (2): Extract") {
  doNotOptimizeAway(Result<Int?, any Error>.success(.some(42))[case: \.success.some])
}

let kp: CaseKeyPath<Result<Int?, any Error>, Int> = \.success.some
benchmark("Append Case Key Path (2): Embed (Cached)") {
  doNotOptimizeAway(kp(42))
}
benchmark("Append Case Key Path (2): Extract (Cached)") {
  doNotOptimizeAway(Result<Int?, any Error>.success(.some(42))[case: kp])
}

let acp = kp.asCasePath()
benchmark("Append Case Key Path (2): Embed (Erased any)") {
  doNotOptimizeAway(acp.embed(42))
}
benchmark("Append Case Key Path (2): Extract (Erased any)") {
  doNotOptimizeAway(acp.extract(from: .success(.some(42))))
}

benchmark("Append Case Key Path (10): Embed") {
  let ckp: CaseKeyPath<Foo, Void> = \.foo.foo.foo.foo.foo.foo.foo.foo.foo.bar
  doNotOptimizeAway(ckp(()))
}
benchmark("Append Case Key Path (10): Extract") {
  doNotOptimizeAway(
    Foo.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.bar)))))))))[
      case: \.foo.foo.foo.foo.foo.foo.foo.foo.foo.bar
    ]
  )
}

let kp2: CaseKeyPath<Foo, Void> = \.foo.foo.foo.foo.foo.foo.foo.foo.foo.bar
benchmark("Append Case Key Path (10): Embed (Cached)") {
  doNotOptimizeAway(kp2(()))
}
benchmark("Append Case Key Path (10): Extract (Cached)") {
  doNotOptimizeAway(Foo.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.bar)))))))))[case: kp2])
}

let acp2 = kp2.asCasePath()
benchmark("Append Case Key Path (10): Embed (Erased any)") {
  doNotOptimizeAway(acp2.embed(()))
}
benchmark("Append Case Key Path (10): Extract (Erased any)") {
  doNotOptimizeAway(
    acp2.extract(from: Foo.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.bar))))))))))
  )
}

benchmark("Dynamic Member Case Key Path (10): Extract") {
  let foo = Foo.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.bar)))))))))
  doNotOptimizeAway(foo.foo?.foo?.foo?.foo?.foo?.foo?.foo?.foo?.foo?.bar)
}

Benchmark.main([
  defaultBenchmarkSuite,
])
