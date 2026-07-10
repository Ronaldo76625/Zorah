// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Zorah",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "Zorah", targets: ["Zorah"])
    ],
    targets: [
        .executableTarget(
            name: "Zorah",
            path: "Sources/Zorah"
        )
    ],
    swiftLanguageModes: [.v5]
)
