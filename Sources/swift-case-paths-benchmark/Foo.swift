import CasePaths

@dynamicMemberLookup
public enum Foo: CasePathable {
  case foo(Foo2)

  @inlinable
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public struct AllCasePaths {
    @inlinable
    public var foo: some CasePathProtocol<Foo, Foo2> { _Foo() }
    @inlinable
    public init() {}

    public struct _Foo: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Foo2) -> Foo { .foo(value) }
      @inlinable
      public func extract(from root: Foo) -> Foo2? {
        guard case let .foo(value) = root else { return nil }
        return value
      }
    }
  }
}

@dynamicMemberLookup
public enum Foo2: CasePathable {
  case foo(Foo3)

  @inlinable
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public struct AllCasePaths {
    @inlinable
    public var foo: some CasePathProtocol<Foo2, Foo3> { _Foo() }
    @inlinable
    public init() {}

    public struct _Foo: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Foo3) -> Foo2 { .foo(value) }
      @inlinable
      public func extract(from root: Foo2) -> Foo3? {
        guard case let .foo(value) = root else { return nil }
        return value
      }
    }
  }
}

@dynamicMemberLookup
public enum Foo3: CasePathable {
  case foo(Foo4)

  @inlinable
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public struct AllCasePaths {
    @inlinable
    public var foo: some CasePathProtocol<Foo3, Foo4> { _Foo() }
    @inlinable
    public init() {}

    public struct _Foo: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Foo4) -> Foo3 { .foo(value) }
      @inlinable
      public func extract(from root: Foo3) -> Foo4? {
        guard case let .foo(value) = root else { return nil }
        return value
      }
    }
  }
}

@dynamicMemberLookup
public enum Foo4: CasePathable {
  case foo(Foo5)

  @inlinable
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public struct AllCasePaths {
    @inlinable
    public var foo: some CasePathProtocol<Foo4, Foo5> { _Foo() }
    @inlinable
    public init() {}

    public struct _Foo: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Foo5) -> Foo4 { .foo(value) }
      @inlinable
      public func extract(from root: Foo4) -> Foo5? {
        guard case let .foo(value) = root else { return nil }
        return value
      }
    }
  }
}

@dynamicMemberLookup
public enum Foo5: CasePathable {
  case foo(Foo6)

  @inlinable
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public struct AllCasePaths {
    @inlinable
    public var foo: some CasePathProtocol<Foo5, Foo6> { _Foo() }
    @inlinable
    public init() {}

    public struct _Foo: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Foo6) -> Foo5 { .foo(value) }
      @inlinable
      public func extract(from root: Foo5) -> Foo6? {
        guard case let .foo(value) = root else { return nil }
        return value
      }
    }
  }
}

@dynamicMemberLookup
public enum Foo6: CasePathable {
  case foo(Foo7)

  @inlinable
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public struct AllCasePaths {
    @inlinable
    public var foo: some CasePathProtocol<Foo6, Foo7> { _Foo() }
    @inlinable
    public init() {}

    public struct _Foo: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Foo7) -> Foo6 { .foo(value) }
      @inlinable
      public func extract(from root: Foo6) -> Foo7? {
        guard case let .foo(value) = root else { return nil }
        return value
      }
    }
  }
}

@dynamicMemberLookup
public enum Foo7: CasePathable {
  case foo(Foo8)

  @inlinable
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public struct AllCasePaths {
    @inlinable
    public var foo: some CasePathProtocol<Foo7, Foo8> { _Foo() }
    @inlinable
    public init() {}

    public struct _Foo: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Foo8) -> Foo7 { .foo(value) }
      @inlinable
      public func extract(from root: Foo7) -> Foo8? {
        guard case let .foo(value) = root else { return nil }
        return value
      }
    }
  }
}

@dynamicMemberLookup
public enum Foo8: CasePathable {
  case foo(Foo9)

  @inlinable
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public struct AllCasePaths {
    @inlinable
    public var foo: some CasePathProtocol<Foo8, Foo9> { _Foo() }
    @inlinable
    public init() {}

    public struct _Foo: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Foo9) -> Foo8 { .foo(value) }
      @inlinable
      public func extract(from root: Foo8) -> Foo9? {
        guard case let .foo(value) = root else { return nil }
        return value
      }
    }
  }
}

@dynamicMemberLookup
public enum Foo9: CasePathable {
  case foo(Foo10)

  @inlinable
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public struct AllCasePaths {
    @inlinable
    public var foo: some CasePathProtocol<Foo9, Foo10> { _Foo() }
    @inlinable
    public init() {}

    public struct _Foo: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Foo10) -> Foo9 { .foo(value) }
      @inlinable
      public func extract(from root: Foo9) -> Foo10? {
        guard case let .foo(value) = root else { return nil }
        return value
      }
    }
  }
}

@dynamicMemberLookup
public enum Foo10: CasePathable {
  case bar

  @inlinable
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public struct AllCasePaths {
    @inlinable
    public var bar: some CasePathProtocol<Foo10, Void> { _Bar() }
    @inlinable
    public init() {}

    public struct _Bar: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Void) -> Foo10 { .bar }
      @inlinable
      public func extract(from root: Foo10) -> Void? {
        guard case .bar = root else { return nil }
        return ()
      }
    }
  }
}
