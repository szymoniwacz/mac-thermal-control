import Foundation

public enum Signal: String, CaseIterable, Encodable {
    case hardwareInventory = "hardware_inventory"
    case cpuActivity = "cpu_activity"
    case thermalPressure = "thermal_pressure"
    case powerContext = "power_context"
    case gpuInventory = "gpu_inventory"
    case gpuActivity = "gpu_activity"
    case fans, temperatures, frequency, power
    case performanceLimits = "performance_limits"
}

public enum ObservationStatus: String, CaseIterable, Encodable {
    case ok
    case notImplemented = "not_implemented"
    case unsupported, missing
    case permissionDenied = "permission_denied"
    case invalid, unverified, stale, timeout, error
}

public enum ObservationValue: Encodable {
    case number(Double)
    case text(String)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .number(let number): try container.encode(number)
        case .text(let text): try container.encode(text)
        }
    }
}

public enum ContractError: Error {
    case invalidConfiguration, invalidObservation, oversizedOutput
}

/// Typed values prevent absent telemetry from becoming an implicit zero.
/// No source access or arbitrary raw payload is part of this layer.
public struct Observation: Encodable {
    public let signal: Signal
    public let sourceID: String
    public let status: ObservationStatus
    public let value: ObservationValue?
    public let unit: String?
    public let observedAt: String?
    public let checkedAt: String
    public let method: String
    public let reason: String?
    public let inputs: [String]
    public let windowSeconds: Double?

    public init(signal: Signal, sourceID: String, value: ObservationValue, unit: String?,
                observedAt: String, method: String = "direct", inputs: [String] = [],
                windowSeconds: Double? = nil) throws {
        if case .number(let number) = value {
            guard number.isFinite, let unit = unit,
                  !unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ContractError.invalidObservation
            }
        }
        if case .text = value, unit != nil { throw ContractError.invalidObservation }
        guard ["direct", "derived"].contains(method), !sourceID.isEmpty,
              !observedAt.isEmpty,
              method != "derived" || (!inputs.isEmpty && windowSeconds != nil),
              windowSeconds.map({ $0.isFinite && $0 > 0 }) ?? true else {
            throw ContractError.invalidObservation
        }
        self.signal = signal
        self.sourceID = sourceID
        status = .ok
        self.value = value
        self.unit = unit
        self.observedAt = observedAt
        checkedAt = observedAt
        self.method = method
        reason = nil
        self.inputs = inputs
        self.windowSeconds = windowSeconds
    }

    public init(gap signal: Signal, status: ObservationStatus, sourceID: String = "none",
                checkedAt: String, reason: String) throws {
        guard status != .ok, !reason.isEmpty, !sourceID.isEmpty, !checkedAt.isEmpty else {
            throw ContractError.invalidObservation
        }
        self.signal = signal
        self.sourceID = sourceID
        self.status = status
        value = nil
        unit = nil
        observedAt = nil
        self.checkedAt = checkedAt
        method = "direct"
        self.reason = reason
        inputs = []
        windowSeconds = nil
    }

    private enum CodingKeys: String, CodingKey {
        case signal, sourceID, status, value, unit, observedAt, checkedAt
        case method, reason, inputs, windowSeconds
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(signal, forKey: .signal)
        try container.encode(sourceID, forKey: .sourceID)
        try container.encode(status, forKey: .status)
        // Explicit nulls are intentional contract fields, not omitted keys.
        try container.encode(value, forKey: .value)
        try container.encode(unit, forKey: .unit)
        try container.encode(observedAt, forKey: .observedAt)
        try container.encode(checkedAt, forKey: .checkedAt)
        try container.encode(method, forKey: .method)
        try container.encode(reason, forKey: .reason)
        try container.encode(inputs, forKey: .inputs)
        try container.encode(windowSeconds, forKey: .windowSeconds)
    }
}
