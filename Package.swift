// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "MacThermalControl",
    platforms: [.macOS(.v12)],
    products: [.executable(name: "mac-thermal-control", targets: ["ThermalCLI"])],
    targets: [
        .target(name: "DiscoveryCore"),
        .executableTarget(name: "ThermalCLI", dependencies: ["DiscoveryCore"]),
        .executableTarget(name: "ContractTests", dependencies: ["DiscoveryCore"],
                          path: "tests/DiscoveryCoreTests")
    ]
)
