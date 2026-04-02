// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "swift-link-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Link Primitives",
            targets: ["Link Primitives"]
        ),
        .library(
            name: "Link Primitives Test Support",
            targets: ["Link Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-vector-primitives"),
    ],
    targets: [
        .target(
            name: "Link Primitives",
            dependencies: [
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Vector Primitives", package: "swift-vector-primitives"),
            ]
        ),
        .target(
            name: "Link Primitives Test Support",
            dependencies: [
                "Link Primitives",
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
                .product(name: "Vector Primitives Test Support", package: "swift-vector-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Link Primitives Tests",
            dependencies: [
                "Link Primitives",
                "Link Primitives Test Support",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
