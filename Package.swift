// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Refresher",
    platforms: [.iOS(.v11)],
    products: [
        .library(
            name: "Refresher",
            targets: ["Refresher"])
    ],
    targets: [
        .target(
            name: "Refresher",
            path: "Sources")
    ]
)
