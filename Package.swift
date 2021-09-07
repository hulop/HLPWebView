// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "HLPWebView",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "HLPWebView", targets: ["HLPWebView"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "HLPWebView",
            resources: [
                .process("icons.xcassets")
            ]
        ),
        .testTarget(
            name: "HLPWebViewTest",
            dependencies: ["HLPWebView"]),
    ]
)
