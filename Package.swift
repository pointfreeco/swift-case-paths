// swift-tools-version:5.1
import PackageDescription

let package = Package(
  name: "CasePaths",
  products: [
    .library(
      name: "CasePaths",
      type: .dynamic,
      targets: ["CasePaths"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "CasePaths",
      dependencies: []),
    .testTarget(
      name: "CasePathsTests",
      dependencies: ["CasePaths"]),
  ]
)
