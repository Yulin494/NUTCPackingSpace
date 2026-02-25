// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NUTCParkingShared",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "NUTCParkingShared", targets: ["NUTCParkingShared"]),
    ],
    targets: [
        .target(name: "NUTCParkingShared"),
    ]
)
