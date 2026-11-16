import Foundation
import DiscoveryCore
import CNativeInventory
@_spi(Testing) import DiscoveryNative

// Every reader below supplies a fake call. Never invoke the default native reader.
func require(_ condition: Bool, _ message: String = "",
             file: StaticString = #filePath, line: UInt = #line) {
    guard condition else { fatalError("\(file):\(line) \(message)") }
}

func response(_ bytes: [UInt8], count: Int? = nil,
              status: mtc_inventory_status = MTC_INVENTORY_OK) -> mtc_inventory_result {
    var result = mtc_inventory_result()
    result.status = status
    result.count = count ?? bytes.count
    withUnsafeMutableBytes(of: &result.bytes) { storage in
        for (offset, byte) in bytes.enumerated() { storage[offset] = byte }
    }
    return result
}

let time = "2001-01-01T00:00:00Z"
let fields: [(PublicInventoryField, mtc_inventory_field)] = [
    (.model, MTC_MODEL), (.machine, MTC_MACHINE), (.cpuBrand, MTC_CPU_BRAND),
    (.osBuild, MTC_OS_BUILD), (.memory, MTC_MEMORY),
    (.logicalCPUCount, MTC_LOGICAL_CPUS), (.physicalCPUCount, MTC_PHYSICAL_CPUS)
]
func encoded(_ observation: Observation) throws -> String {
    String(decoding: try JSONEncoder().encode(observation), as: UTF8.self)
}
for (field, native) in fields {
    var calls = 0
    let payload: [UInt8] = field.unit == nil ? [65, 0] : [1] + [UInt8](repeating: 0, count: field.capacity - 1)
    let reader = NativeInventoryReader { received, capacity in
        calls += 1
        require(received == native && capacity == field.capacity)
        return response(payload)
    }
    let observation = try PublicInventory.read(field, using: reader, checkedAt: time)
    require(calls == 1 && observation.status == .ok && observation.sourceID == field.sourceID)
    require(observation.checkedAt == time && observation.observedAt == time)
    require(observation.unit == field.unit)
    for capacity in [Int.min, -1, 0, field.capacity - 1, field.capacity + 1, Int.max] {
        if case .failure(.invalidResponse) = reader.read(field, capacity: capacity) {} else { fatalError() }
    }
    require(calls == 1)
    do {
        _ = try PublicInventory.read(field, using: reader, checkedAt: "")
        fatalError("Empty metadata accepted")
    } catch {}
    require(calls == 1)
    let statuses: [(mtc_inventory_status, ObservationStatus, String)] = [
        (MTC_INVENTORY_DENIED, .permissionDenied, "inventory_permission_denied"),
        (MTC_INVENTORY_UNSUPPORTED, .unsupported, "inventory_unsupported"),
        (MTC_INVENTORY_BUFFER_TOO_SMALL, .invalid, "inventory_buffer_too_small"),
        (MTC_INVENTORY_ERROR, .error, "inventory_read_failed"),
        (MTC_INVENTORY_INVALID, .invalid, "inventory_invalid_native_response"),
        (mtc_inventory_status(rawValue: 999), .invalid, "inventory_invalid_native_response")
    ]
    for (status, expected, reason) in statuses {
        var attempts = 0
        let failed = NativeInventoryReader { _, _ in
            attempts += 1
            return response(Array("private-source-dump".utf8), count: Int.max, status: status)
        }
        let gap = try PublicInventory.read(field, using: failed, checkedAt: time)
        require(attempts == 1 && gap.status == expected && gap.reason == reason)
        require(gap.value == nil && gap.observedAt == nil && gap.sourceID == field.sourceID)
        let json = try encoded(gap)
        require(json.contains("\"value\":null") && !json.contains("private-source-dump"))
    }
    for count in [0, field.capacity + 1, Int.max] {
        let oversized = NativeInventoryReader { _, _ in response(payload, count: count) }
        let gap = try PublicInventory.read(field, using: oversized, checkedAt: time)
        require(gap.status == .invalid && gap.reason == "inventory_invalid_native_response")
    }
}
for payload: [UInt8] in [[0], [65], [65, 0, 66, 0], [255, 0], [32, 0]] {
    let reader = NativeInventoryReader { _, _ in response(payload) }
    require(try PublicInventory.read(.model, using: reader, checkedAt: time).status == .invalid)
}
for integer: UInt64 in [1, 9_007_199_254_740_993, UInt64.max] {
    let bytes = (0..<8).map { UInt8(truncatingIfNeeded: integer >> ($0 * 8)) }
    let reader = NativeInventoryReader { _, _ in response(bytes) }
    let observation = try PublicInventory.read(.memory, using: reader, checkedAt: time)
    require(try encoded(observation).contains("\"value\":\(integer)"))
}
for field: PublicInventoryField in [.logicalCPUCount, .physicalCPUCount] {
    for payload: [UInt8] in [[0, 0, 0, 0], [255, 255, 255, 255], [0, 0, 0, 128], [1, 0, 0]] {
        let reader = NativeInventoryReader { _, _ in response(payload) }
        require(try PublicInventory.read(field, using: reader, checkedAt: time).status == .invalid)
    }
}
// Initialization alone performs no source access.
_ = NativeInventoryReader()
print("PASS Swift native bridge mapping, bounds, fixed gaps, normalization and exact JSON (fake calls only)")
