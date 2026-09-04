// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TillyCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "TillyCore", targets: ["TillyCore"])
    ],
    targets: [
        .target(name: "TillyCore"),
        .testTarget(name: "TillyCoreTests", dependencies: ["TillyCore"])
    ]
)
