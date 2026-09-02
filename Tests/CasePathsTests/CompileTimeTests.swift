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

private enum HandWrittenConformance {
  case foo(Int)
  case bar
}

@available(*, deprecated)
extension HandWrittenConformance: CasePathable {
  struct AllCasePaths {
    var foo: AnyCasePath<HandWrittenConformance, Int> {
      AnyCasePath(
        embed: { .foo($0) },
        extract: {
          guard case .foo(let value) = $0 else { return nil }
          return value
        }
      )
    }

    var bar: AnyCasePath<HandWrittenConformance, Void> {
      AnyCasePath(
        embed: { .bar },
        extract: {
          guard case .bar = $0 else { return nil }
          return ()
        }
      )
    }
  }

  static var allCasePaths: AllCasePaths { AllCasePaths() }
}
