import Benchmark
import CasePaths

/*
 name                                                      time         std        iterations
 --------------------------------------------------------------------------------------------
 Case Path Reflection (Appended: 2): Embed                   250.000 ns ±  31.24 %    1000000
 Case Path Reflection (Appended: 2): Extract                 708.000 ns ±  32.00 %    1000000
 Case Path Reflection (Appended: 2, Cached): Embed            41.000 ns ±  67.30 %    1000000
 Case Path Reflection (Appended: 2, Cached): Extract         333.000 ns ±  43.49 %    1000000
 Case Key Path (Appended: 2): Embed                         4083.000 ns ±   9.37 %     346309
 Case Key Path (Appended: 2): Extract                       4541.000 ns ±   6.09 %     307882
 Case Key Path (Appended: 2, Cached): Embed                 1958.000 ns ±  17.72 %     709441
 Case Key Path (Appended: 2, Cached): Extract               2417.000 ns ± 118.76 %     572773
 Case Key Path (Appended: 2, Cached + Converted): Embed      958.000 ns ±  14.47 %    1000000
 Case Key Path (Appended: 2, Cached + Converted): Extract   1417.000 ns ±  15.08 %     990935
 Case Path Reflection (Appended: 10): Embed                 1709.000 ns ±   8.49 %     816699
 Case Path Reflection (Appended: 10): Extract               4750.000 ns ±   6.49 %     293788
 Case Path Reflection (Appended: 10, Cached): Embed           83.000 ns ±  28.79 %    1000000
 Case Path Reflection (Appended: 10, Cached): Extract       1917.000 ns ±  13.23 %     723330
 Case Key Path (Appended: 10): Embed                       12416.000 ns ±  15.25 %     112901
 Case Key Path (Appended: 10): Extract                     13833.000 ns ± 167.15 %     102161
 Case Key Path (Appended: 10, Cached): Embed                8000.000 ns ±   4.86 %     175509
 Case Key Path (Appended: 10, Cached): Extract              9333.000 ns ±   5.80 %     150034
 Case Key Path (Appended: 10, Cached + Converted): Embed    3625.000 ns ±   5.56 %     381696
 Case Key Path (Appended: 10, Cached + Converted): Extract  4875.000 ns ±   8.08 %     285089
 Case Pathable (Dynamic Member Lookup: 10)                     0.000 ns ±    inf %     1000000
 */

benchmark("Case Path Reflection (Appended: 2): Embed") {
  let cp = /Result<Int?, any Error>.success .. /Int?.some
  doNotOptimizeAway(cp.embed(42))
}
benchmark("Case Path Reflection (Appended: 2): Extract") {
  let cp = /Result<Int?, any Error>.success .. /Int?.some
  doNotOptimizeAway(cp.extract(from: .success(.some(42))))
}

let cp = /Result<Int?, any Error>.success .. /Int?.some
benchmark("Case Path Reflection (Appended: 2, Cached): Embed") {
  doNotOptimizeAway(cp.embed(42))
}
benchmark("Case Path Reflection (Appended: 2, Cached): Extract") {
  doNotOptimizeAway(cp.extract(from: .success(.some(42))))
}

benchmark("Case Key Path (Appended: 2): Embed") {
  let ckp: CaseKeyPath<Result<Int?, any Error>, Int> = \.success.some
  doNotOptimizeAway(ckp(42))
}
benchmark("Case Key Path (Appended: 2): Extract") {
  let ckp: CaseKeyPath<Result<Int?, any Error>, Int> = \.success.some
  doNotOptimizeAway(Result<Int?, any Error>.success(.some(42))[case: ckp])
}

let ckp: CaseKeyPath<Result<Int?, any Error>, Int> = \.success.some
benchmark("Case Key Path (Appended: 2, Cached): Embed") {
  doNotOptimizeAway(ckp(42))
}
benchmark("Case Key Path (Appended: 2, Cached): Extract") {
  doNotOptimizeAway(Result<Int?, any Error>.success(.some(42))[case: ckp])
}

let acp = AnyCasePath(ckp)
benchmark("Case Key Path (Appended: 2, Cached + Converted): Embed") {
  doNotOptimizeAway(acp.embed(42))
}
benchmark("Case Key Path (Appended: 2, Cached + Converted): Extract") {
  doNotOptimizeAway(acp.extract(from: .success(.some(42))))
}

#if swift(>=5.9)
  benchmark("Case Path Reflection (Appended: 10): Embed") {
    let cp = (/Foo.foo)
      .appending(path: /Foo2.foo)
      .appending(path: /Foo3.foo)
      .appending(path: /Foo4.foo)
      .appending(path: /Foo5.foo)
      .appending(path: /Foo6.foo)
      .appending(path: /Foo7.foo)
      .appending(path: /Foo8.foo)
      .appending(path: /Foo9.foo)
      .appending(path: /Foo10.bar)
    doNotOptimizeAway(cp.embed(()))
  }
  benchmark("Case Path Reflection (Appended: 10): Extract") {
    let cp = (/Foo.foo)
      .appending(path: /Foo2.foo)
      .appending(path: /Foo3.foo)
      .appending(path: /Foo4.foo)
      .appending(path: /Foo5.foo)
      .appending(path: /Foo6.foo)
      .appending(path: /Foo7.foo)
      .appending(path: /Foo8.foo)
      .appending(path: /Foo9.foo)
      .appending(path: /Foo10.bar)
    doNotOptimizeAway(cp.extract(from: .foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.bar)))))))))))
  }

  let cp2 = (/Foo.foo)
    .appending(path: /Foo2.foo)
    .appending(path: /Foo3.foo)
    .appending(path: /Foo4.foo)
    .appending(path: /Foo5.foo)
    .appending(path: /Foo6.foo)
    .appending(path: /Foo7.foo)
    .appending(path: /Foo8.foo)
    .appending(path: /Foo9.foo)
    .appending(path: /Foo10.bar)
  benchmark("Case Path Reflection (Appended: 10, Cached): Embed") {
    doNotOptimizeAway(cp2.embed(()))
  }
  benchmark("Case Path Reflection (Appended: 10, Cached): Extract") {
    doNotOptimizeAway(cp2.extract(from: .foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.bar)))))))))))
  }

  benchmark("Case Key Path (Appended: 10): Embed") {
    let ckp: CaseKeyPath<Foo, Void> = \.foo.foo.foo.foo.foo.foo.foo.foo.foo.bar
    doNotOptimizeAway(ckp(()))
  }
  benchmark("Case Key Path (Appended: 10): Extract") {
    let ckp: CaseKeyPath<Foo, Void> = \.foo.foo.foo.foo.foo.foo.foo.foo.foo.bar
    doNotOptimizeAway(
      Foo.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.bar)))))))))[case: ckp]
    )
  }

  let ckp2: CaseKeyPath<Foo, Void> = \.foo.foo.foo.foo.foo.foo.foo.foo.foo.bar
  benchmark("Case Key Path (Appended: 10, Cached): Embed") {
    doNotOptimizeAway(ckp2(()))
  }
  benchmark("Case Key Path (Appended: 10, Cached): Extract") {
    doNotOptimizeAway(Foo.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.bar)))))))))[case: ckp2])
  }

  let acp2 = AnyCasePath(ckp2)
  benchmark("Case Key Path (Appended: 10, Cached + Converted): Embed") {
    doNotOptimizeAway(acp2.embed(()))
  }
  benchmark("Case Key Path (Appended: 10, Cached + Converted): Extract") {
    doNotOptimizeAway(
      acp2.extract(from: Foo.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.bar))))))))))
    )
  }

  benchmark("Case Pathable (Dynamic Member Lookup: 10)") {
    let foo = Foo.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.foo(.bar)))))))))
    doNotOptimizeAway(foo.foo?.foo?.foo?.foo?.foo?.foo?.foo?.foo?.foo?.bar)
  }
#endif

Benchmark.main([
  defaultBenchmarkSuite
])
