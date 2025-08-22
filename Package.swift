// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Proofreader",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "Proofreader", targets: ["Proofreader"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Proofreader",
            dependencies: [
                "Alamofire"
            ],
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
