public protocol CasePathReflectable<Root> {
  associatedtype Root: CasePathable
  subscript(root: Root) -> PartialCaseKeyPath<Root> { get }
}
