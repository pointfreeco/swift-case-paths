import CasePaths

@CasePathable
private enum Comments {
  // Comment above case
  case bar
  /*Comment before case*/ case baz(Int)
  case fizz(buzz: String)  // Comment on case
  case fizzier /*Comment in case*/(Int, buzzier: String)
  case fizziest
}

@CasePathable
enum Action {
  case alert(Alert)
}

@CasePathable
enum Alert {
  case alert(Never)
}
