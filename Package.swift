// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AtrestFastingApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "UI", targets: ["UI"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Policy", targets: ["Policy"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: ["Domain", "Data", "UI", "DesignSystem", "Policy"],
            path: "Sources/App"
        ),
        .target(
            name: "Domain",
            dependencies: []
        ),
        .target(
            name: "Data",
            dependencies: ["Domain", "Policy"]
        ),
        .target(
            name: "DesignSystem",
            dependencies: ["Domain"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "Policy",
            dependencies: ["Domain"]
        ),
        .target(
            name: "UI",
            dependencies: ["Domain", "Data", "DesignSystem", "Policy"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "UnitTests",
            dependencies: ["Domain", "Data", "UI", "DesignSystem", "Policy"]
        ),
        .testTarget(
            name: "SnapshotTests",
            dependencies: [
                "UI",
                "DesignSystem",
                "Data",
                "Domain",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        .testTarget(
            name: "PolicyTests",
            dependencies: ["Policy"]
        )
    ]
)
