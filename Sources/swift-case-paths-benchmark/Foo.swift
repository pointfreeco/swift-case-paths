#if swift(>=5.9)
  import CasePaths

  @CasePathable
  @dynamicMemberLookup
  public enum Foo {
    case foo(Foo2)
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Foo2 {
    case foo(Foo3)
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Foo3 {
    case foo(Foo4)
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Foo4 {
    case foo(Foo5)
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Foo5 {
    case foo(Foo6)
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Foo6 {
    case foo(Foo7)
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Foo7 {
    case foo(Foo8)
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Foo8 {
    case foo(Foo9)
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Foo9 {
    case foo(Foo10)
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Foo10 {
    case bar
  }
#endif
