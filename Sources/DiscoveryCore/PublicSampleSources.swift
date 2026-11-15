import Foundation

/// Fixed HOST_CPU_LOAD_INFO-shaped result supplied by a fake reader.
/// A future native shim must verify SDK widths/counts and balance its host port.
public enum CPUTickReadResult {
    /// Counters in user, system, idle, nice order; count is in elements, not bytes.
    case success(counters: [UInt32], returnedCount: Int)
    /// An unclassified Mach failure is an error, never inferred permission denial.
    case failure
}

/// No arbitrary Mach flavor, native implementation, retry or deadline is provided.
public protocol PublicCPUTickReader {
    func readCPUTicks() -> CPUTickReadResult
}

public struct PublicCPUTickReading {
    public let ticks: CPUTicks
    public let checkedAt: String
    public var observedAt: String { checkedAt }
    public var sourceID: String { PublicCPUTicks.sourceID }
}

public enum PublicCPUTickResult {
    /// Raw cumulative ticks, not an activity percentage or throughput measurement.
    case success(PublicCPUTickReading)
    case gap(Observation)
}

public enum PublicCPUTicks {
    public static let sourceID = "public.mach.cpu_ticks.v1"

    /// One injected read. The caller owns baseline resets, timing and source policy.
    public static func read(using reader: PublicCPUTickReader,
                            checkedAt: String) throws -> PublicCPUTickResult {
        guard !checkedAt.isEmpty else { throw ContractError.invalidObservation }
        func gap(_ status: ObservationStatus, _ reason: String) throws -> PublicCPUTickResult {
            .gap(try Observation(gap: .cpuActivity, status: status, sourceID: sourceID,
                                 checkedAt: checkedAt, reason: reason))
        }
        switch reader.readCPUTicks() {
        case .failure:
            return try gap(.error, "cpu_ticks_read_failed")
        case .success(let counters, let count):
            guard count == 4, counters.count == 4 else {
                return try gap(.invalid, "cpu_ticks_invalid_count")
            }
            return .success(PublicCPUTickReading(
                ticks: CPUTicks(user: UInt64(counters[0]), system: UInt64(counters[1]),
                                idle: UInt64(counters[2]), nice: UInt64(counters[3])),
                checkedAt: checkedAt))
        }
    }
}

/// A future Foundation adapter must explicitly map known states and @unknown default.
/// No raw enum number or free-form source data crosses this contract.
public enum PublicThermalState: CaseIterable {
    case nominal, fair, serious, critical, unknown
}

public protocol PublicThermalStateReader {
    func readThermalState() -> PublicThermalState
}

public enum PublicThermalPressure {
    public static let sourceID = "public.foundation.thermal_state.v1"

    /// Unitless category only. Even nominal may be returned on unsupported systems;
    /// success does not prove a supported sensor, temperature, freshness or safety.
    public static func read(using reader: PublicThermalStateReader,
                            checkedAt: String) throws -> Observation {
        guard !checkedAt.isEmpty else { throw ContractError.invalidObservation }
        let category: String
        switch reader.readThermalState() {
        case .nominal: category = "nominal"
        case .fair: category = "fair"
        case .serious: category = "serious"
        case .critical: category = "critical"
        case .unknown:
            return try Observation(gap: .thermalPressure, status: .unverified,
                                   sourceID: sourceID, checkedAt: checkedAt,
                                   reason: "thermal_state_unknown")
        }
        return try Observation(signal: .thermalPressure, sourceID: sourceID,
                               value: .text(category), unit: nil, observedAt: checkedAt)
    }
}
