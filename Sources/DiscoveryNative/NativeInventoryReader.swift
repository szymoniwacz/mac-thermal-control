import CNativeInventory
import DiscoveryCore

/// Synchronous native inventory access for a future isolated worker only.
/// Construction performs no reads. Not linked into the synthetic CLI.
public struct NativeInventoryReader: PublicInventoryReader {
    private let call: (mtc_inventory_field, Int) -> mtc_inventory_result

    public init() { call = { mtc_inventory_read($0, $1) } }

    // Fixture-only SPI keeps the standalone test runner usable in release builds
    // without enabling @testable access in the production module.
    @_spi(Testing) public init(call: @escaping (mtc_inventory_field, Int) -> mtc_inventory_result) {
        self.call = call
    }

    public func read(_ field: PublicInventoryField, capacity: Int) -> InventoryReadResult {
        guard capacity == field.capacity else { return .failure(.invalidResponse) }
        let nativeField: mtc_inventory_field
        switch field {
        case .model: nativeField = MTC_MODEL
        case .machine: nativeField = MTC_MACHINE
        case .cpuBrand: nativeField = MTC_CPU_BRAND
        case .osBuild: nativeField = MTC_OS_BUILD
        case .memory: nativeField = MTC_MEMORY
        case .logicalCPUCount: nativeField = MTC_LOGICAL_CPUS
        case .physicalCPUCount: nativeField = MTC_PHYSICAL_CPUS
        }
        var result = call(nativeField, capacity)
        switch result.status {
        case MTC_INVENTORY_OK:
            guard result.count > 0, result.count <= capacity else {
                return .failure(.invalidResponse)
            }
            let bytes = withUnsafeBytes(of: &result.bytes) { Array($0.prefix(result.count)) }
            return .success(bytes: bytes, returnedCount: result.count)
        case MTC_INVENTORY_DENIED: return .failure(.permissionDenied)
        case MTC_INVENTORY_UNSUPPORTED: return .failure(.unsupported)
        case MTC_INVENTORY_BUFFER_TOO_SMALL: return .failure(.insufficientBuffer)
        case MTC_INVENTORY_ERROR: return .failure(.error)
        default: return .failure(.invalidResponse)
        }
    }
}
