public protocol CasePathIterable: CasePathable
where AllCasePaths: Sequence, AllCasePaths.Element == PartialCaseKeyPath<Self> {}
