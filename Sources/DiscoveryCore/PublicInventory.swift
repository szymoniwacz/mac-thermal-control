import Foundation

/// Fixed sysctl subset of the adopted public inventory design. No native reader ships here.
public enum PublicInventoryField: CaseIterable {
    case model, machine, cpuBrand, osBuild, memory, logicalCPUCount, physicalCPUCount

    public var selector: String {
        switch self {
        case .model: return "hw.model"
        case .machine: return "hw.machine"
        case .cpuBrand: return "machdep.cpu.brand_string"
        case .osBuild: return "kern.osversion"
        case .memory: return "hw.memsize"
        case .logicalCPUCount: return "hw.logicalcpu"
        case .physicalCPUCount: return "hw.physicalcpu"
        }
    }

    public var sourceID: String {
        let suffix: String
        switch self {
        case .model: suffix = "model"
        case .machine: suffix = "machine"
        case .cpuBrand: suffix = "cpu_brand"
        case .osBuild: suffix = "os_build"
        case .memory: suffix = "memory"
        case .logicalCPUCount: suffix = "logical_cpu_count"
        case .physicalCPUCount: suffix = "physical_cpu_count"
        }
        return "public.sysctl.\(suffix).v1"
    }

    public var capacity: Int {
        switch self {
        case .model, .machine: return 128
        case .cpuBrand, .osBuild: return 256
        case .memory: return 8
        case .logicalCPUCount, .physicalCPUCount: return 4
        }
    }

    public var unit: String? {
        switch self {
        case .memory: return "bytes"
        case .logicalCPUCount, .physicalCPUCount: return "count"
        default: return nil
        }
    }
}

/// A future native shim must classify errno itself and never expose raw diagnostics.
public enum InventoryReadFailure: CaseIterable {
    case permissionDenied, unsupported, insufficientBuffer, error
}

public enum InventoryReadResult {
    /// Initialized bounded storage, plus the native API's separately returned length.
    case success(bytes: [UInt8], returnedCount: Int)
    /// No partial buffer is accepted after a failed read, including ENOMEM.
    case failure(InventoryReadFailure)
}

/// Inject a fake in tests. This interface cannot request arbitrary keys or setters.
/// It does not enforce native call safety, deadlines or isolation of a future implementation.
public protocol PublicInventoryReader {
    func read(_ field: PublicInventoryField, capacity: Int) -> InventoryReadResult
}

public enum PublicInventory {
    /// One attempt only. The caller owns capability/failure policy and session timing.
    /// Intel byte order and widths are explicit; no pointer casts or host reads occur here.
    public static func read(_ field: PublicInventoryField, using reader: PublicInventoryReader,
                            checkedAt: String) throws -> Observation {
        // Reject invalid metadata before invoking even an injected source.
        guard !checkedAt.isEmpty else { throw ContractError.invalidObservation }
        func gap(_ status: ObservationStatus, _ reason: String) throws -> Observation {
            try Observation(gap: .hardwareInventory, status: status, sourceID: field.sourceID,
                            checkedAt: checkedAt, reason: reason)
        }
        switch reader.read(field, capacity: field.capacity) {
        case .failure(let failure):
            switch failure {
            case .permissionDenied: return try gap(.permissionDenied, "inventory_permission_denied")
            case .unsupported: return try gap(.unsupported, "inventory_unsupported")
            case .insufficientBuffer: return try gap(.invalid, "inventory_buffer_too_small")
            case .error: return try gap(.error, "inventory_read_failed")
            }
        case .success(let bytes, let count):
            guard count > 0, count <= field.capacity, count <= bytes.count,
                  bytes.count <= field.capacity else {
                return try gap(.invalid, "inventory_invalid_length")
            }
            let payload = bytes.prefix(count)
            let value: ObservationValue
            if field.unit == nil {
                guard payload.last == 0,
                      payload.dropLast().allSatisfy({ $0 >= 32 && $0 <= 126 }) else {
                    return try gap(.invalid, "inventory_invalid_string")
                }
                // Printable ASCII was checked before decoding. Only ASCII spaces can trim.
                let text = String(decoding: payload.dropLast(), as: UTF8.self)
                    .trimmingCharacters(in: .whitespaces)
                guard !text.isEmpty else { return try gap(.invalid, "inventory_empty_string") }
                value = .text(text)
            } else {
                guard count == field.capacity else {
                    return try gap(.invalid, "inventory_invalid_width")
                }
                var integer: UInt64 = 0
                for (offset, byte) in payload.enumerated() {
                    integer |= UInt64(byte) << (offset * 8)
                }
                guard integer > 0,
                      field == .memory || integer <= UInt64(Int32.max) else {
                    return try gap(.invalid, "inventory_invalid_integer")
                }
                value = .unsignedInteger(integer)
            }
            return try Observation(signal: .hardwareInventory, sourceID: field.sourceID,
                                   value: value, unit: field.unit, observedAt: checkedAt)
        }
    }
}
