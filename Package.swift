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
          path: "HLPWebView",
          resources: [
            .copy("hlp_bridge.js"),
            .copy("ios_bridge.js")
          ]
        ),
        .testTarget(
            name: "HLPWebViewTest",
            dependencies: ["HLPWebView"]),
    ]
)
