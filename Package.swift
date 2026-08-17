// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "KickstartSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
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
