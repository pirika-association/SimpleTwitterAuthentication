// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "SimpleTwitterAuthentication",
    platforms: [.iOS(.v10)],
    products: [
        .library(name: "SimpleTwitterAuthentication", targets: ["SimpleTwitterAuthentication"])
    ],
    dependencies: [
        .package(url: "https://github.com/OAuthSwift/OAuthSwift.git", .upToNextMajor(from: "2.1.0"))
    ],
    targets: [
        .target(name: "SimpleTwitterAuthentication", dependencies: ["OAuthSwift"], path: "Sources")
    ],
    swiftLanguageVersions: [.v5]
)
