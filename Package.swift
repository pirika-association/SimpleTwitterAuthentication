import PackageDescription

let package = Package(
    platforms: [.iOS(.v10)],
    name: "SimpleTwitterAuthentication",
    products: [
        .library(name: "SimpleTwitterAuthentication", targets: ["SimpleTwitterAuthentication"])
    ],
    dependencies: [
        .package(name: "OAuthSwift", url: "https://github.com/OAuthSwift/OAuthSwift.git", .upToNextMajor(from: "2.1.0"))
    ],
    targets: [
        .target(name: "SimpleTwitterAuthentication", path: "Sources")
    ],
    swiftLanguageVersions: [.v5]
)
