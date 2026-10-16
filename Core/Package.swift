// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "TillyCore",
    platforms: [.iOS(.v27), .macOS(.v27)],
    products: [
        .library(name: "TillyCore", targets: ["TillyCore"])
    ],
    targets: [
        .target(name: "TillyCore"),
        .testTarget(name: "TillyCoreTests", dependencies: ["TillyCore"])
    ]
)
