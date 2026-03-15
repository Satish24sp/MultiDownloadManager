// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DownloadManagerKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "DownloadManagerKit",
            targets: ["DownloadManagerKit"]
        )
    ],
    targets: [
        .target(
            name: "DownloadManagerKit",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "DownloadManagerKitTests",
            dependencies: ["DownloadManagerKit"]
        )
    ]
)

