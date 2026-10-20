// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_miniaudio",
    platforms: [
        .iOS("13.0"),
        .macOS("10.13")
    ],
    products: [
        .library(name: "flutter-miniaudio", type: .dynamic, targets: ["flutter_miniaudio"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_miniaudio",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/flutter_miniaudio")
            ]
        )
    ]
)
