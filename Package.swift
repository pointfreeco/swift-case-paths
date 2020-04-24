// swift-tools-version:5.1
import PackageDescription

let package = Package(
  name: "CasePaths",
  products: [
    .library(
      name: "CasePaths",
      targets: ["CasePaths"]),
    .library(
      name: "CasePaths-dynamic",
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
