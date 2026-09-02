import CasePaths

@CasePathable
private enum EnumWithExtractAndEmbedCase {
  case embed
  case extract
}

#if DEBUG
  @available(*, deprecated, message: "Deprecated")
#else
  @available(iOS, deprecated: 9999, message: "Deprecated")
  @available(macOS, deprecated: 9999, message: "Deprecated")
#endif
@CasePathable
private enum EnumWithConditionalAvailability {
  case foo(Int)
  case bar
}
