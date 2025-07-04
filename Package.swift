// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.
// swift 6.x 的deinit有问题, 暂时留在5.10

import PackageDescription

let package = Package(
    name: "JFHeroBrowser",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "JFHeroBrowser",
            targets: ["JFHeroBrowser"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/JerryFans/JRBaseKit", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "JFHeroBrowser",
            dependencies: ["JRBaseKit"],
            resources: [.process("Resources/Assets")])
    ]
)
