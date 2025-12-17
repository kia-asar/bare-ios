// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CStudioKit",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "CStudioKit",
            targets: ["CStudioKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
        .package(url: "https://github.com/kean/NukeUI", from: "0.8.3"),
        .package(url: "https://github.com/OneSignal/OneSignal-XCFramework", from: "5.2.15")
    ],
    targets: [
        .target(
            name: "CStudioKit",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Auth", package: "supabase-swift"),
                .product(name: "Functions", package: "supabase-swift"),
                .product(name: "PostgREST", package: "supabase-swift"),
                .product(name: "Realtime", package: "supabase-swift"),
                .product(name: "Storage", package: "supabase-swift"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "NukeUI", package: "NukeUI"),
                .product(name: "OneSignalFramework", package: "OneSignal-XCFramework")
            ],
            path: "Sources/CStudioKit",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CStudioKitTests",
            dependencies: ["CStudioKit"],
            path: "Tests/CStudioKitTests"
        )
    ]
)


