import Foundation
import DiscoveryCore

final class ContractTests {
    private func object<T: Encodable>(_ value: T) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try unwrap(JSONSerialization.jsonObject(with: encoder.encode(value)) as? [String: Any])
    }

    func testEveryGapStatusSerializesNullInsteadOfZeroOrAnObservationTime() throws {
        for status in ObservationStatus.allCases where status != .ok {
            let gap = try Observation(gap: .fans, status: status,
                                      checkedAt: "2001-01-01T00:00:01Z", reason: "fixture_gap")
            let json = try object(gap)
            expectEqual(json["status"] as? String, status.rawValue)
            expectTrue(json["value"] is NSNull)
            expectTrue(json["unit"] is NSNull)
            expectTrue(json["observed_at"] is NSNull)
            expectEqual(json["checked_at"] as? String, "2001-01-01T00:00:01Z")
        }
    }

    func testObservedZeroRetainsValueUnitAndProvenance() throws {
        let observation = try Observation(signal: .cpuActivity, sourceID: "fixture.idle",
            value: .number(0), unit: "percent", observedAt: "2001-01-01T00:00:01Z")
        let json = try object(observation)
        expectEqual(json["value"] as? Double, 0)
        expectEqual(json["unit"] as? String, "percent")
        expectEqual(json["source_id"] as? String, "fixture.idle")
        expectEqual(json["status"] as? String, "ok")
    }

    func testInvalidObservationsAreRejected() {
        for number in [Double.nan, .infinity, -.infinity] {
            expectThrowsError(try Observation(signal: .cpuActivity, sourceID: "fixture",
                value: .number(number), unit: "percent", observedAt: "fixture_time"))
        }
        expectThrowsError(try Observation(gap: .fans, status: .ok,
                                            checkedAt: "fixture_time", reason: "gap"))
        expectThrowsError(try Observation(gap: .fans, status: .missing,
                                            checkedAt: "fixture_time", reason: ""))
        expectThrowsError(try Observation(signal: .cpuActivity, sourceID: "fixture",
            value: .number(30), unit: "percent", observedAt: "fixture_time", method: "derived"))
    }

    func testNumericUnitsAreRequiredWhileCategoriesHaveNoPhysicalUnit() throws {
        for unit in [nil, "", " \n"] as [String?] {
            expectThrowsError(try Observation(signal: .cpuActivity, sourceID: "fixture",
                value: .number(0), unit: unit, observedAt: "fixture_time"))
        }
        let category = try Observation(signal: .thermalPressure, sourceID: "fixture",
            value: .text("nominal"), unit: nil, observedAt: "fixture_time")
        expectThrowsError(try Observation(signal: .thermalPressure, sourceID: "fixture",
            value: .text("nominal"), unit: "percent", observedAt: "fixture_time"))
        let json = try object(category)
        expectTrue(json["unit"] is NSNull)
        expectEqual(json["value"] as? String, "nominal")
    }

    func testOversizedMetadataCannotProduceAnOversizedRecord() throws {
        expectThrowsError(try DemoReport.render(format: .json,
            configuration: CollectionConfiguration(), sessionID: String(repeating: "x", count: 65536)))
        expectThrowsError(try DemoReport.render(format: .jsonl,
            configuration: CollectionConfiguration(), sessionID: String(repeating: "x", count: 65536)))
    }

    func testConfigurationRejectsNonfiniteAndOutOfBoundsValues() {
        for interval in [Double.nan, .infinity, -.infinity, -1, 0, 0.5, 61] {
            expectThrowsError(try CollectionConfiguration(intervalSeconds: interval))
        }
        for duration in [Double.nan, .infinity, -.infinity, -1, 0, 0.5, 601] {
            expectThrowsError(try CollectionConfiguration(durationSeconds: duration))
        }
    }

    func testConfigurationBoundsCapFramesWithoutRoundingUp() throws {
        expectEqual(try CollectionConfiguration(intervalSeconds: 1, durationSeconds: 600).frameCount, 600)
        expectEqual(try CollectionConfiguration(intervalSeconds: 60, durationSeconds: 1).frameCount, 0)
        expectEqual(try CollectionConfiguration(intervalSeconds: 1.5, durationSeconds: 2).frameCount, 1)
    }

    func testCPUDeltaNeedsTwoSamplesAndPreservesIdleZero() {
        var delta = CPUActivityDelta()
        expectNil(delta.percentage(ticks: CPUTicks(user: 20, system: 10, idle: 70),
                                      elapsed: 0, requestedInterval: 1))
        expectEqual(delta.percentage(ticks: CPUTicks(user: 20, system: 10, idle: 170),
                                        elapsed: 1, requestedInterval: 1), 0)
        expectEqual(delta.percentage(ticks: CPUTicks(user: 40, system: 20, idle: 240),
                                        elapsed: 2, requestedInterval: 1), 30)
    }

    func testCPUCounterResetGapClockDiscontinuityAndExplicitReset() {
        var delta = CPUActivityDelta()
        func sample(_ ticks: UInt64, _ time: Double) -> Double? {
            delta.percentage(ticks: CPUTicks(user: ticks, system: 0, idle: ticks),
                             elapsed: time, requestedInterval: 1)
        }
        expectNil(sample(100, 0))
        expectNil(sample(1, 1)) // Counter decrease resets the baseline.
        expectEqual(sample(2, 2), 50)
        expectNil(sample(3, 10)) // Sleep-like gap resets the baseline.
        expectEqual(sample(4, 11), 50)
        expectNil(sample(5, 11)) // No positive interval.
        expectNil(sample(6, 9)) // Monotonic time regression.
        expectNil(sample(7, .nan))
        expectNil(sample(8, 12)) // First sample after invalid timing.
        delta.reset()
        expectNil(sample(9, 13))
    }

    func testCPUZeroTotalIsMissingAndLargeCountersDoNotOverflow() {
        var delta = CPUActivityDelta()
        let zero = CPUTicks(user: 0, system: 0, idle: 0)
        expectNil(delta.percentage(ticks: zero, elapsed: 0, requestedInterval: 1))
        expectNil(delta.percentage(ticks: zero, elapsed: 1, requestedInterval: 1))
        let huge = CPUTicks(user: .max, system: .max, idle: .max, nice: .max)
        expectEqual(delta.percentage(ticks: huge, elapsed: 2, requestedInterval: 1), 75)
    }

    func testInventoryReportsAllLiveCapabilitiesAsUnimplemented() throws {
        let data = try DemoReport.render(format: .json, configuration: CollectionConfiguration(),
                                         sessionID: "fixture-session")
        let inventory = try unwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        expectEqual(inventory["schema_version"] as? Int, 1)
        expectEqual(inventory["session_id"] as? String, "fixture-session")
        let config = try unwrap(inventory["configuration"] as? [String: Any])
        expectEqual(config["mode"] as? String, "synthetic_demo")
        let capabilities = try unwrap(inventory["capabilities"] as? [[String: Any]])
        expectEqual(Set(capabilities.compactMap { $0["signal"] as? String }),
                       Set(Signal.allCases.map(\.rawValue)))
        expectTrue(capabilities.allSatisfy { $0["status"] as? String == "not_implemented" })
    }

    func testJSONLTimingSequenceCompletionAndSyntheticProvenance() throws {
        let config = try CollectionConfiguration(intervalSeconds: 1.5, durationSeconds: 4)
        let data = try DemoReport.render(format: .jsonl, configuration: config, sessionID: "fixture")
        let records = try data.split(separator: 10).map {
            try unwrap(JSONSerialization.jsonObject(with: Data($0)) as? [String: Any])
        }
        expectEqual(records.compactMap { $0["type"] as? String },
                       ["session_start", "sample", "sample", "session_end"])
        expectEqual(records.compactMap { $0["sequence"] as? Int }, [0, 1, 2, 3])
        expectEqual(records.compactMap { $0["elapsed_seconds"] as? Double }, [0, 1.5, 3, 4])
        expectTrue(records.allSatisfy { $0["session_id"] as? String == "fixture" })
        let observations = try unwrap(records[1]["observations"] as? [[String: Any]])
        expectEqual(observations.count, Signal.allCases.count)
        let cpu = try unwrap(observations.first { $0["signal"] as? String == "cpu_activity" })
        expectEqual(cpu["value"] as? Double, 30)
        expectEqual(cpu["source_id"] as? String, "fixture.cpu_ticks.v1")
        expectEqual(cpu["window_seconds"] as? Double, 1.5)
        expectEqual(records.last?["completed_frame_count"] as? Int, 2)
        expectEqual(records.last?["complete"] as? Bool, true)
        expectEqual(data.last, 10)
    }

    func testMaximumDemoStaysWithinRecordAndSessionCaps() throws {
        let data = try DemoReport.render(format: .jsonl,
            configuration: CollectionConfiguration(durationSeconds: 600))
        let lines = data.split(separator: 10)
        expectEqual(lines.count, 602)
        expectLessThanOrEqual(data.count, DemoReport.maximumOutputBytes)
        expectTrue(lines.allSatisfy { $0.count + 1 <= DemoReport.maximumRecordBytes })
    }

    func testDefaultAndAllUnsupportedCommandsCannotCollectOrEchoArguments() {
        for arguments in [[], ["capture"], ["--live"], ["--demo", "--sudo"],
                          ["--demo", "--format"], ["--demo", "--format", "xml"],
                          ["--demo", "--interval", "nan"], ["--demo", "--duration", "inf"],
                          ["--demo", "--demo"], ["--demo", "--help"],
                          ["--demo", "--duration", "600", "--duration", "1"],
                          ["--demo", "private-user-value"]] {
            let result = Command.run(arguments: arguments)
            expectEqual(result.exitCode, 2, "\(arguments)")
            expectTrue(result.output.isEmpty)
            expectFalse(result.diagnostic.contains("private-user-value"))
        }
    }

    func testHelpAndDemoAreExplicitlySynthetic() throws {
        expectEqual(Command.run(arguments: ["--help"]).exitCode, 0)
        for format in ["json", "jsonl"] {
            let result = Command.run(arguments: ["--demo", "--format", format])
            expectEqual(result.exitCode, 0)
            expectTrue(result.diagnostic.contains("No hardware accessed"))
            expectTrue(String(decoding: result.output, as: UTF8.self).contains("synthetic_demo"))
        }
    }
}

let suite = ContractTests()
let cases: [(String, () throws -> Void)] = [
    ("testEveryGapStatusSerializesNullInsteadOfZeroOrAnObservationTime", { try suite.testEveryGapStatusSerializesNullInsteadOfZeroOrAnObservationTime() }),
    ("testObservedZeroRetainsValueUnitAndProvenance", { try suite.testObservedZeroRetainsValueUnitAndProvenance() }),
    ("testInvalidObservationsAreRejected", { suite.testInvalidObservationsAreRejected() }),
    ("testNumericUnitsAreRequiredWhileCategoriesHaveNoPhysicalUnit", {
        try suite.testNumericUnitsAreRequiredWhileCategoriesHaveNoPhysicalUnit()
    }),
    ("testOversizedMetadataCannotProduceAnOversizedRecord", {
        try suite.testOversizedMetadataCannotProduceAnOversizedRecord()
    }),
    ("testConfigurationRejectsNonfiniteAndOutOfBoundsValues", { suite.testConfigurationRejectsNonfiniteAndOutOfBoundsValues() }),
    ("testConfigurationBoundsCapFramesWithoutRoundingUp", { try suite.testConfigurationBoundsCapFramesWithoutRoundingUp() }),
    ("testCPUDeltaNeedsTwoSamplesAndPreservesIdleZero", { suite.testCPUDeltaNeedsTwoSamplesAndPreservesIdleZero() }),
    ("testCPUCounterResetGapClockDiscontinuityAndExplicitReset", { suite.testCPUCounterResetGapClockDiscontinuityAndExplicitReset() }),
    ("testCPUZeroTotalIsMissingAndLargeCountersDoNotOverflow", { suite.testCPUZeroTotalIsMissingAndLargeCountersDoNotOverflow() }),
    ("testInventoryReportsAllLiveCapabilitiesAsUnimplemented", { try suite.testInventoryReportsAllLiveCapabilitiesAsUnimplemented() }),
    ("testJSONLTimingSequenceCompletionAndSyntheticProvenance", { try suite.testJSONLTimingSequenceCompletionAndSyntheticProvenance() }),
    ("testMaximumDemoStaysWithinRecordAndSessionCaps", { try suite.testMaximumDemoStaysWithinRecordAndSessionCaps() }),
    ("testDefaultAndAllUnsupportedCommandsCannotCollectOrEchoArguments", { suite.testDefaultAndAllUnsupportedCommandsCannotCollectOrEchoArguments() }),
    ("testHelpAndDemoAreExplicitlySynthetic", { try suite.testHelpAndDemoAreExplicitlySynthetic() })
]
for (name, run) in cases {
    let before = failureCount
    do { try run() } catch { failureCount += 1; print("FAIL \(name): \(error)") }
    if before == failureCount { print("PASS \(name)") }
}
print("\(cases.count) cases; \(failureCount) failures")
exit(failureCount == 0 ? 0 : 1)
