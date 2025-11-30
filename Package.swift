// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "select_foods",
    products: [
        .library(name: "select_foods", targets: ["select_foods"])
    ],
    targets: [
        .target(
            name: "select_foods",
            path: "src"
        ),
        .testTarget(
            name: "select_foodsTests",
            dependencies: ["select_foods"],
            path: "tests"
        )
    ]
)
