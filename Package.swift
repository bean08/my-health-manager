// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "MyHealthManager",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(name: "MyHealthManager", targets: ["MyHealthManager"])
  ],
  targets: [
    .executableTarget(
      name: "MyHealthManager",
      path: "Sources/MyHealthManager"
    )
  ]
)
