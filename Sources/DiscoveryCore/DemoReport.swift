import Foundation

public struct CollectionConfiguration: Encodable {
    public let mode = "synthetic_demo"
    public let intervalSeconds: Double
    public let durationSeconds: Double
    public var frameCount: Int { Int(floor(durationSeconds / intervalSeconds)) }

    public init(intervalSeconds: Double = 1, durationSeconds: Double = 2) throws {
        guard intervalSeconds.isFinite, durationSeconds.isFinite,
              (1...60).contains(intervalSeconds), (1...600).contains(durationSeconds) else {
            throw ContractError.invalidConfiguration
        }
        self.intervalSeconds = intervalSeconds
        self.durationSeconds = durationSeconds
    }
}

private struct FixtureSource: Encodable {
    let id = "fixture.cpu_ticks.v1"
    let interface = "synthetic CPU counters; no device source"
    let evidence = "Sources/DiscoveryCore/DemoReport.swift"
}

private struct Capability: Encodable {
    let signal: Signal
    let status = ObservationStatus.notImplemented
    let reason = "live_source_not_implemented"
}

private struct Inventory: Encodable {
    let schemaVersion = 1
    let sessionID: String
    let applicationVersion = "0.1.0-dev"
    let configuration: CollectionConfiguration
    let capabilities = Signal.allCases.map { Capability(signal: $0) }
    let sources = [FixtureSource()]
    let observations: [Observation] = []
    let limitations = ["synthetic_demo_not_device_evidence", "discovery_phase_incomplete"]
}

private struct Record: Encodable {
    let schemaVersion = 1
    let sessionID: String
    let sequence: Int
    let type: String
    let wallTime: String
    let elapsedSeconds: Double
    let actualIntervalSeconds: Double?
    let inventory: Inventory?
    let observations: [Observation]?
    let terminationReason: String?
    let completedFrameCount: Int?
    let complete: Bool?
}

public enum OutputFormat: String { case json, jsonl }

/// Exercises serialization with synthetic counters, without clocks, sleeping or source access.
public enum DemoReport {
    public static let maximumRecordBytes = 64 * 1024
    public static let maximumOutputBytes = 8 * 1024 * 1024

    public static func render(format: OutputFormat, configuration: CollectionConfiguration,
                              sessionID: String = UUID().uuidString) throws -> Data {
        let inventory = Inventory(sessionID: sessionID, configuration: configuration)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys]
        func encoded<T: Encodable>(_ value: T) throws -> Data {
            let data = try encoder.encode(value)
            guard data.count + 1 <= maximumRecordBytes else { throw ContractError.oversizedOutput }
            return data + Data([10])
        }
        if format == .json { return try encoded(inventory) }
        var output = Data()
        func append(_ record: Record) throws {
            let data = try encoded(record)
            guard output.count + data.count <= maximumOutputBytes else {
                throw ContractError.oversizedOutput
            }
            output.append(data)
        }
        func wallTime(_ elapsed: Double) -> String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            // Fixed synthetic epoch, never presented as the current device's time.
            return formatter.string(from: Date(timeIntervalSince1970: 978307200 + elapsed))
        }
        try append(Record(sessionID: sessionID, sequence: 0, type: "session_start",
                          wallTime: wallTime(0), elapsedSeconds: 0, actualIntervalSeconds: nil,
                          inventory: inventory, observations: nil, terminationReason: nil,
                          completedFrameCount: nil, complete: nil))
        var cpu = CPUActivityDelta()
        // The baseline is synthetic too, so the first demo sample can show a real delta.
        _ = cpu.percentage(ticks: CPUTicks(user: 0, system: 0, idle: 0), elapsed: 0,
                           requestedInterval: configuration.intervalSeconds)
        for index in 0..<configuration.frameCount {
            let elapsed = Double(index + 1) * configuration.intervalSeconds
            let timestamp = wallTime(elapsed)
            let ticks = UInt64(index + 1)
            let percent = cpu.percentage(ticks: CPUTicks(user: ticks * 20, system: ticks * 10,
                                                        idle: ticks * 70), elapsed: elapsed,
                                         requestedInterval: configuration.intervalSeconds)
            var observations = try Signal.allCases.filter { $0 != .cpuActivity }.map {
                try Observation(gap: $0, status: .notImplemented, checkedAt: timestamp,
                                reason: "live_source_not_implemented")
            }
            if let percent = percent {
                observations.append(try Observation(signal: .cpuActivity,
                    sourceID: "fixture.cpu_ticks.v1", value: .number(percent), unit: "percent",
                    observedAt: timestamp, method: "derived", inputs: ["fixture.cpu_ticks.v1"],
                    windowSeconds: configuration.intervalSeconds))
            }
            try append(Record(sessionID: sessionID, sequence: index + 1, type: "sample",
                              wallTime: timestamp, elapsedSeconds: elapsed,
                              actualIntervalSeconds: configuration.intervalSeconds,
                              inventory: nil, observations: observations, terminationReason: nil,
                              completedFrameCount: nil, complete: nil))
        }
        try append(Record(sessionID: sessionID, sequence: configuration.frameCount + 1,
                          type: "session_end", wallTime: wallTime(configuration.durationSeconds),
                          elapsedSeconds: configuration.durationSeconds, actualIntervalSeconds: nil,
                          inventory: nil, observations: nil, terminationReason: "synthetic_demo_complete",
                          completedFrameCount: configuration.frameCount, complete: true))
        return output
    }
}
