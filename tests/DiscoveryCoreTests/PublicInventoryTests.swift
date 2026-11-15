import Foundation
import DiscoveryCore

private final class FakeInventoryReader: PublicInventoryReader {
    var calls: [(PublicInventoryField, Int)] = []
    var result: InventoryReadResult
    init(_ result: InventoryReadResult) { self.result = result }
    func read(_ field: PublicInventoryField, capacity: Int) -> InventoryReadResult {
        calls.append((field, capacity))
        return result
    }
}

final class PublicInventoryTests {
    private let timestamp = "2001-01-01T00:00:00Z"

    private func read(_ field: PublicInventoryField, _ bytes: [UInt8], count: Int? = nil) throws -> Observation {
        try PublicInventory.read(field, using: FakeInventoryReader(
            .success(bytes: bytes, returnedCount: count ?? bytes.count)), checkedAt: timestamp)
    }

    private func encoded(_ observation: Observation) throws -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return String(decoding: try encoder.encode(observation), as: UTF8.self)
    }

    private func bytes(_ integer: UInt64, width: Int) -> [UInt8] {
        (0..<width).map { UInt8(truncatingIfNeeded: integer >> ($0 * 8)) }
    }

    func allowlistAndSingleRead() throws {
        let expected: [(PublicInventoryField, String, String, Int, String?)] = [
            (.model, "hw.model", "model", 128, nil),
            (.machine, "hw.machine", "machine", 128, nil),
            (.cpuBrand, "machdep.cpu.brand_string", "cpu_brand", 256, nil),
            (.osBuild, "kern.osversion", "os_build", 256, nil),
            (.memory, "hw.memsize", "memory", 8, "bytes"),
            (.logicalCPUCount, "hw.logicalcpu", "logical_cpu_count", 4, "count"),
            (.physicalCPUCount, "hw.physicalcpu", "physical_cpu_count", 4, "count")
        ]
        expectEqual(PublicInventoryField.allCases.count, expected.count)
        for (field, selector, suffix, capacity, unit) in expected {
            expectEqual(field.selector, selector)
            expectEqual(field.sourceID, "public.sysctl.\(suffix).v1")
            expectEqual(field.capacity, capacity)
            expectEqual(field.unit, unit)
            let payload: [UInt8] = unit == nil ? [65, 0] : bytes(1, width: capacity)
            let reader = FakeInventoryReader(.success(bytes: payload, returnedCount: payload.count))
            let observation = try PublicInventory.read(field, using: reader, checkedAt: timestamp)
            expectEqual(reader.calls.count, 1)
            expectEqual(reader.calls.first?.0, field)
            expectEqual(reader.calls.first?.1, capacity)
            expectEqual(observation.status, .ok)
            expectEqual(observation.signal, .hardwareInventory)
            expectEqual(observation.sourceID, "public.sysctl.\(suffix).v1")
            expectEqual(observation.checkedAt, timestamp)
            expectEqual(observation.observedAt, timestamp)
            expectEqual(observation.unit, unit)
            expectEqual(observation.method, "direct")
        }
        let reader = FakeInventoryReader(.failure(.error))
        expectThrowsError(try PublicInventory.read(.model, using: reader, checkedAt: ""))
        expectTrue(reader.calls.isEmpty)
    }

    func failuresAndLengthBounds() throws {
        let failures: [(InventoryReadFailure, ObservationStatus, String)] = [
            (.permissionDenied, .permissionDenied, "inventory_permission_denied"),
            (.unsupported, .unsupported, "inventory_unsupported"),
            (.insufficientBuffer, .invalid, "inventory_buffer_too_small"),
            (.error, .error, "inventory_read_failed")
        ]
        for field in PublicInventoryField.allCases {
            for (failure, status, reason) in failures {
                let reader = FakeInventoryReader(.failure(failure))
                let gap = try PublicInventory.read(field, using: reader, checkedAt: timestamp)
                expectEqual(gap.status, status)
                expectEqual(gap.reason, reason)
                expectEqual(reader.calls.count, 1) // No retries, fallback or another selector.
                expectEqual(reader.calls.first?.0, field)
                expectNil(gap.value)
                expectNil(gap.observedAt)
                let json = try encoded(gap)
                expectTrue(json.contains("\"value\":null"))
                expectTrue(json.contains("\"unit\":null"))
                expectTrue(json.contains("\"observed_at\":null"))
                expectTrue(json.contains(field.sourceID))
            }
            for count in [Int.min, -1, 0, field.capacity + 1, Int.max] {
                let gap = try read(field, [65, 0], count: count)
                expectEqual(gap.status, .invalid)
                expectEqual(gap.reason, "inventory_invalid_length")
                expectNil(gap.value)
            }
            expectEqual(try read(field, [], count: 1).status, .invalid)
            expectEqual(try read(field, [65], count: 2).status, .invalid)
            let oversized = [UInt8](repeating: 65, count: field.capacity + 1)
            expectEqual(try read(field, oversized, count: 1).status, .invalid)
        }
    }

    func boundedStrings() throws {
        for field: PublicInventoryField in [.model, .machine, .cpuBrand, .osBuild] {
            let valid = try read(field, Array("  fixture  ".utf8) + [0])
            if case .text(let text)? = valid.value { expectEqual(text, "fixture") }
            else { expectTrue(false) }
            let maximum = try read(field, [UInt8](repeating: 126, count: field.capacity - 1) + [0])
            expectEqual(maximum.status, .ok)
            if case .text(let text)? = maximum.value { expectEqual(text.count, field.capacity - 1) }
            else { expectTrue(false) }
            // The native returned length, not unused initialized storage, delimits the string.
            let short = try read(field, [65, 0, 255, 66], count: 2)
            expectEqual(short.status, .ok)
            if case .text(let text)? = short.value { expectEqual(text, "A") }
            else { expectTrue(false) }
            for payload: [UInt8] in [[0], [32, 0], [32, 32, 0], [65], [65, 0, 66, 0],
                                    [0, 65, 0], [9, 65, 0], [10, 0], [31, 0], [127, 0],
                                    [128, 0], [195, 169, 0], [255, 0]] {
                let gap = try read(field, payload)
                expectEqual(gap.status, .invalid)
                expectNil(gap.value)
                expectFalse(try encoded(gap).contains("fixture"))
            }
            let sentinel = Array("private-source-dump".utf8) + [0, 65, 0]
            let json = try encoded(read(field, sentinel))
            expectFalse(json.contains("private-source-dump"))
        }
    }

    func integerWidthsAndExactEncoding() throws {
        struct IntegerValue: Decodable { let value: UInt64 }
        for integer: UInt64 in [1, 16_777_217, 9_007_199_254_740_993, UInt64.max] {
            let observation = try read(.memory, bytes(integer, width: 8))
            expectEqual(observation.status, .ok)
            if case .unsignedInteger(let actual)? = observation.value { expectEqual(actual, integer) }
            else { expectTrue(false) }
            let json = try encoded(observation)
            expectTrue(json.contains("\"value\":\(integer)"))
            let decoded = try JSONDecoder().decode(IntegerValue.self, from: Data(json.utf8))
            expectEqual(decoded.value, integer)
        }
        for field: PublicInventoryField in [.logicalCPUCount, .physicalCPUCount] {
            for integer: UInt64 in [1, 256, UInt64(Int32.max)] {
                let observation = try read(field, bytes(integer, width: 4))
                expectEqual(observation.status, .ok)
                if case .unsignedInteger(let actual)? = observation.value { expectEqual(actual, integer) }
                else { expectTrue(false) }
            }
            for invalid: UInt64 in [0, 2_147_483_648, UInt64(UInt32.max)] {
                let gap = try read(field, bytes(invalid, width: 4))
                expectEqual(gap.status, .invalid)
                expectEqual(gap.reason, "inventory_invalid_integer")
                expectNil(gap.value)
            }
        }
        for field: PublicInventoryField in [.memory, .logicalCPUCount, .physicalCPUCount] {
            for count in 1..<field.capacity {
                let gap = try read(field, bytes(1, width: field.capacity), count: count)
                expectEqual(gap.status, .invalid)
                expectEqual(gap.reason, "inventory_invalid_width")
            }
            expectEqual(try read(field, bytes(0, width: field.capacity)).status, .invalid)
        }
        // The generic exact-integer value still permits a real zero, with required units.
        let zero = try Observation(signal: .hardwareInventory, sourceID: "fixture",
            value: .unsignedInteger(0), unit: "bytes", observedAt: timestamp)
        expectTrue(try encoded(zero).contains("\"value\":0"))
        for unit in [nil, "", " \n"] as [String?] {
            expectThrowsError(try Observation(signal: .hardwareInventory, sourceID: "fixture",
                value: .unsignedInteger(1), unit: unit, observedAt: timestamp))
        }
    }
}
