// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NUTCParkingShared",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v13)      // 讓 `swift test` 能在 macOS host(含 CI runner)上執行純邏輯測試
    ],
    products: [
        .library(name: "NUTCParkingShared", targets: ["NUTCParkingShared"]),
    ],
    targets: [
        .target(name: "NUTCParkingShared"),
        .testTarget(name: "NUTCParkingSharedTests", dependencies: ["NUTCParkingShared"]),
    ]
)
