import Foundation
import DiscoveryCore

private final class FakeCPUReader: PublicCPUTickReader {
    var calls = 0
    var result: CPUTickReadResult
    init(_ result: CPUTickReadResult) { self.result = result }
    func readCPUTicks() -> CPUTickReadResult { calls += 1; return result }
}

private final class FakeThermalReader: PublicThermalStateReader {
    var calls = 0
    var state: PublicThermalState
    init(_ state: PublicThermalState) { self.state = state }
    func readThermalState() -> PublicThermalState { calls += 1; return state }
}

final class PublicSampleSourcesTests {
    private let timestamp = "2001-01-01T00:00:00Z"

    private func ticks(_ counters: [UInt32]) throws -> PublicCPUTickReading {
        let result = try PublicCPUTicks.read(using: FakeCPUReader(
            .success(counters: counters, returnedCount: 4)), checkedAt: timestamp)
        guard case .success(let reading) = result else { throw ContractError.invalidObservation }
        return reading
    }

    private func json(_ observation: Observation) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try unwrap(JSONSerialization.jsonObject(with: encoder.encode(observation)) as? [String: Any])
    }

    func cpuOrderBoundsAndProvenance() throws {
        for counters: [UInt32] in [[1, 2, 3, 4], [0, 0, 0, 0],
                                   [.max, .max, .max, .max], [0, .max, 0, .max]] {
            let reader = FakeCPUReader(.success(counters: counters, returnedCount: 4))
            let result = try PublicCPUTicks.read(using: reader, checkedAt: timestamp)
            expectEqual(reader.calls, 1)
            guard case .success(let reading) = result else { expectTrue(false); continue }
            expectEqual(reading.ticks.user, UInt64(counters[0]))
            expectEqual(reading.ticks.system, UInt64(counters[1]))
            expectEqual(reading.ticks.idle, UInt64(counters[2]))
            expectEqual(reading.ticks.nice, UInt64(counters[3]))
            expectEqual(reading.sourceID, "public.mach.cpu_ticks.v1")
            expectEqual(reading.checkedAt, timestamp)
            expectEqual(reading.observedAt, timestamp)
        }
        let reader = FakeCPUReader(.failure)
        expectThrowsError(try PublicCPUTicks.read(using: reader, checkedAt: ""))
        expectEqual(reader.calls, 0)
    }

    func cpuFailuresAndCountUnits() throws {
        var results: [CPUTickReadResult] = [.failure]
        // Returned count is four natural_t elements, never the 16-byte storage size.
        for count in [Int.min, -1, 0, 1, 3, 5, 16, Int.max] {
            results.append(.success(counters: [1, 2, 3, 4], returnedCount: count))
        }
        for size in [0, 1, 3, 5, 16] {
            results.append(.success(counters: [UInt32](repeating: 7, count: size), returnedCount: 4))
        }
        for (index, input) in results.enumerated() {
            let reader = FakeCPUReader(input)
            let result = try PublicCPUTicks.read(using: reader, checkedAt: timestamp)
            expectEqual(reader.calls, 1)
            guard case .gap(let gap) = result else { expectTrue(false); continue }
            expectEqual(gap.status, index == 0 ? .error : .invalid)
            expectEqual(gap.reason, index == 0 ? "cpu_ticks_read_failed" : "cpu_ticks_invalid_count")
            expectEqual(gap.signal, .cpuActivity)
            expectEqual(gap.sourceID, "public.mach.cpu_ticks.v1")
            expectEqual(gap.checkedAt, timestamp)
            let encoded = try json(gap)
            expectTrue(encoded["value"] is NSNull)
            expectTrue(encoded["unit"] is NSNull)
            expectTrue(encoded["observed_at"] is NSNull)
            expectEqual(encoded["method"] as? String, "direct")
        }
    }

    func cpuDeltaHandoff() throws {
        var delta = CPUActivityDelta()
        let initial = try ticks([1, 2, 3, 4]).ticks
        expectNil(delta.percentage(ticks: initial, elapsed: 0, requestedInterval: 1))
        expectNil(delta.percentage(ticks: initial, elapsed: 1, requestedInterval: 1)) // zero total
        let idle = try ticks([1, 2, 13, 4]).ticks
        expectEqual(delta.percentage(ticks: idle, elapsed: 2, requestedInterval: 1), 0)
        let busy = try ticks([2, 4, 19, 5]).ticks // user +1, system +2, idle +6, nice +1
        expectEqual(delta.percentage(ticks: busy, elapsed: 3, requestedInterval: 1), 40)
        let reset = try ticks([0, 0, 0, 0]).ticks
        expectNil(delta.percentage(ticks: reset, elapsed: 4, requestedInterval: 1))
        delta.reset() // Future runtime must explicitly reset after gaps/failures.
        expectNil(delta.percentage(ticks: busy, elapsed: 5, requestedInterval: 1))
    }

    func thermalCategoriesAndUnknown() throws {
        let expected: [(PublicThermalState, String?)] = [
            (.nominal, "nominal"), (.fair, "fair"), (.serious, "serious"),
            (.critical, "critical"), (.unknown, nil)
        ]
        expectEqual(PublicThermalState.allCases.count, expected.count)
        for (state, category) in expected {
            let reader = FakeThermalReader(state)
            let observation = try PublicThermalPressure.read(using: reader, checkedAt: timestamp)
            expectEqual(reader.calls, 1)
            expectEqual(observation.signal, .thermalPressure)
            expectEqual(observation.sourceID, "public.foundation.thermal_state.v1")
            expectEqual(observation.checkedAt, timestamp)
            expectEqual(observation.method, "direct")
            let encoded = try json(observation)
            expectTrue(encoded["unit"] is NSNull)
            if let category = category {
                expectEqual(observation.status, .ok)
                expectEqual(encoded["value"] as? String, category)
                expectEqual(observation.observedAt, timestamp)
                expectNil(observation.reason)
            } else {
                expectEqual(observation.status, .unverified)
                expectEqual(observation.reason, "thermal_state_unknown")
                expectTrue(encoded["value"] is NSNull)
                expectTrue(encoded["observed_at"] is NSNull)
            }
        }
        let reader = FakeThermalReader(.critical)
        expectThrowsError(try PublicThermalPressure.read(using: reader, checkedAt: ""))
        expectEqual(reader.calls, 0)
    }

    func independentReadersAndNoCaching() throws {
        let failed = FakeCPUReader(.failure)
        let good = FakeCPUReader(.success(counters: [1, 2, 3, 4], returnedCount: 4))
        let unknown = FakeThermalReader(.unknown)
        let known = FakeThermalReader(.fair)
        _ = try PublicCPUTicks.read(using: failed, checkedAt: timestamp)
        _ = try PublicCPUTicks.read(using: good, checkedAt: timestamp)
        expectEqual(try PublicThermalPressure.read(using: unknown, checkedAt: timestamp).status, .unverified)
        expectEqual(try PublicThermalPressure.read(using: known, checkedAt: timestamp).status, .ok)
        good.result = .failure
        guard case .gap = try PublicCPUTicks.read(using: good, checkedAt: timestamp) else {
            expectTrue(false); return
        }
        known.state = .unknown
        expectEqual(try PublicThermalPressure.read(using: known, checkedAt: timestamp).status, .unverified)
        expectEqual(failed.calls, 1)
        expectEqual(good.calls, 2)
        expectEqual(unknown.calls, 1)
        expectEqual(known.calls, 2)
    }
}
