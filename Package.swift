// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "MacThermalControl",
    platforms: [.macOS(.v12)],
    products: [.executable(name: "mac-thermal-control", targets: ["ThermalCLI"])],
    targets: [
        .target(name: "DiscoveryCore"),
        .target(name: "CNativeInventory"),
        .target(name: "DiscoveryNative", dependencies: ["DiscoveryCore", "CNativeInventory"]),
        .executableTarget(name: "ThermalCLI", dependencies: ["DiscoveryCore"]),
        .executableTarget(name: "ContractTests", dependencies: ["DiscoveryCore"],
                          path: "tests/DiscoveryCoreTests"),
        .executableTarget(name: "NativeContractTests",
                          dependencies: ["DiscoveryNative", "CNativeInventory", "DiscoveryCore"],
                          path: "tests/DiscoveryNativeTests")
    ]
)
