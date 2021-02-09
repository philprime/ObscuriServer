// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "ObscuriServer",
    products: [
        .library(name: "ObscuriServer", targets: ["ObscuriServer"]),
    ],
    dependencies: [
        .package(name: "JSONOverTCP", url: "git@bitbucket.org:techprimate/jsonovertcp.git", .upToNextMajor(from: "0.0.1"))
    ],
    targets: [
        .target(name: "ObscuriServer", dependencies: [
            "JSONOverTCP"
        ]),
        .testTarget(name: "ObscuriServerTests", dependencies: ["ObscuriServer"]),
    ]
)
