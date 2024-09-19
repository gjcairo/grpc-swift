// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "RouteGuide",
  platforms: [.macOS(.v15)],
  dependencies: [
    .package(url: "https://github.com/grpc/grpc-swift", branch: "main"),
    .package(url: "https://github.com/apple/swift-protobuf", from: "1.27.0"),
  ],
  targets: []
)