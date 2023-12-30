import Benchmark
import CasePaths

/*
 name                                            time         std        iterations
 ----------------------------------------------------------------------------------
 Append Case Key Path (2): Embed                  3875.000 ns ±  17.89 %     353143
 Append Case Key Path (2): Extract                3959.000 ns ±  11.28 %     347505
 Append Case Key Path (2): Embed (Cached)         2042.000 ns ±  13.62 %     676259
 Append Case Key Path (2): Extract (Cached)       2125.000 ns ±  14.24 %     645592
 Append Case Key Path (2): Embed (Erased any)       42.000 ns ± 109.04 %    1000000
 Append Case Key Path (2): Extract (Erased any)    125.000 ns ±  67.23 %    1000000
 Append Case Key Path (10): Embed                 9542.000 ns ±   6.93 %     145782
 Append Case Key Path (10): Extract              10125.000 ns ±   8.04 %     136875
 Append Case Key Path (10): Embed (Cached)        5583.000 ns ±   7.33 %     248340
 Append Case Key Path (10): Extract (Cached)      6167.000 ns ±  10.18 %     226213
 Append Case Key Path (10): Embed (Erased any)      42.000 ns ± 116.11 %    1000000
 Append Case Key Path (10): Extract (Erased any)   584.000 ns ±  31.32 %    1000000
 Dynamic Member Case Key Path (10): Extract          0.000 ns ±    inf %    1000000
 */

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
