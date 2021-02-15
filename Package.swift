// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "ObscuriServer",
    platforms: [
        .macOS(.v10_14), .iOS(.v12)
    ],
    products: [
        .library(name: "ObscuriCore", targets: ["ObscuriCore"]),
        .library(name: "ObscuriServer", targets: ["ObscuriServer"]),
    ],
    dependencies: [
        .package(name: "JSONOverTCP", url: "git@bitbucket.org:techprimate/jsonovertcp.git", .upToNextMajor(from: "0.0.1"))
    ],
    targets: [
        .target(name: "ObscuriCore"),
        .target(name: "ObscuriServer", dependencies: [
            "ObscuriCore",
            "JSONOverTCP"
        ], resources: [
            .copy("Resources/server.crt"),
            .copy("Resources/server.key"),
            .copy("Resources/keystore.p12")
        ]),
        .testTarget(name: "ObscuriServerTests", dependencies: ["ObscuriServer"]),
    ]
)
