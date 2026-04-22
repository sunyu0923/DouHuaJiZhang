// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DouHuaJiZhang",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DouHuaJiZhang",
            targets: ["DouHuaJiZhang"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.10.0"),
    ],
    targets: [
        .target(
            name: "DouHuaJiZhang",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "DouHuaJiZhangTests",
            dependencies: [
                "DouHuaJiZhang",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
    ]
)
