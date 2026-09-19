// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "KickstartSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "KickstartExchange",
            targets: ["KickstartExchange"]
        )
    ],
    targets: [
        .target(
            name: "KickstartExchange",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "KickstartExchangeTests",
            dependencies: ["KickstartExchange"],
            resources: [
                .process("Fixtures")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
