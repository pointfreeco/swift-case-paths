// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "swift-case-paths",
  products: [
    .library(
      name: "CasePaths",
      targets: ["CasePaths"]
    )
  ],
  dependencies: [
    .package(name: "Benchmark", url: "https://github.com/google/swift-benchmark", from: "0.1.0")
  ],
  targets: [
    .target(
      name: "CasePaths"
    ),
    .testTarget(
      name: "CasePathsTests",
      dependencies: ["CasePaths"]
    ),
    .target(
      name: "swift-case-paths-benchmark",
      dependencies: [
        "CasePaths",
        .product(name: "Benchmark", package: "Benchmark"),
      ]
    ),
  ]
)
