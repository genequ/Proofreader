// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Proofreader",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Proofreader", targets: ["Proofreader"])
    ],
    targets: [
        .executableTarget(
            name: "Proofreader",
            dependencies: [],
            path: "Sources",
            resources: [.process("../Resources")]
        ),
        .testTarget(
            name: "ProofreaderTests",
            dependencies: ["Proofreader"],
            path: "Tests"
        )
    ]
)
