#if canImport(Testing) && swift(>=6)
  import CasePaths
  import Testing

  struct OptionalPathsTests {
    @Test func basics() {
      let path: OptionalKeyPath<A, Int> = \.b.c.d.count

      var a = A(b: .c(C(d: D(count: 42))))
      #expect(path.extract(from: a) == 42)

      a.b.modify(\.c.d.count) { $0 += 1 }
      #expect(path.extract(from: a) == 43)

      a.b.modify(\.c.d) { $0 = nil }
      #expect(path.extract(from: a) == nil)

      let partialPath: PartialKeyPath = path

      a = A(b: .c(C(d: D(count: 42))))
      #expect(partialPath.extract(from: a) as? Int == 42)

      a.b.modify(\.c.d) { $0 = nil }
      #expect(partialPath.extract(from: a) == nil)

      #expect(partialPath(123) == nil)

      #expect(partialPath("123") == nil)
    }

    @Test func optional() {
      let path: OptionalKeyPath<C, D> = \.d
      let appendedPath: OptionalKeyPath<C, Int> = \.d.count

      var c = C()
      #expect(path.extract(from: c) == nil)
      #expect(appendedPath.extract(from: c) == nil)

      path.set(into: &c, D())
      #expect(c.d == D())

      appendedPath.set(into: &c, 1)
      #expect(c.d == D(count: 1))

      appendedPath.modify(into: &c) { $0 += 1 }
      #expect(c.d == D(count: 2))
    }

    struct A: Equatable {
      var b: B
    }
    @CasePathable enum B: Equatable {
      case c(C)
      case z
    }
    struct C: Equatable {
      var d: D?
    }
    struct D: Equatable {
      var count = 0
    }
  }
#endif
