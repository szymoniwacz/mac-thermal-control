import Foundation

/// Counter arithmetic only. Reading Mach/SMC or any other live source is out of scope.
public struct CPUTicks {
    public let user: UInt64
    public let system: UInt64
    public let idle: UInt64
    public let nice: UInt64

    public init(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64 = 0) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }

    var counters: [UInt64] { [user, system, idle, nice] }
}

public struct CPUActivityDelta {
    private var previous: (ticks: CPUTicks, elapsed: Double)?

    public init() {}

    public mutating func reset() { previous = nil }

    /// nil means insufficient or discontinuous data; zero is a valid idle interval.
    public mutating func percentage(ticks: CPUTicks, elapsed: Double,
                                    requestedInterval: Double) -> Double? {
        guard elapsed.isFinite, elapsed >= 0, requestedInterval.isFinite,
              requestedInterval > 0 else {
            reset()
            return nil
        }
        let old = previous
        previous = (ticks, elapsed)
        guard let old = old else { return nil }
        let interval = elapsed - old.elapsed
        guard interval > 0, interval <= 2 * requestedInterval else { return nil }
        var deltas: [UInt64] = []
        for (current, prior) in zip(ticks.counters, old.ticks.counters) {
            guard current >= prior else { return nil } // Reset/wrap; never guess a modulus.
            deltas.append(current - prior)
        }
        // Convert before summing to avoid integer overflow over long-lived counters.
        let total = deltas.reduce(0.0) { $0 + Double($1) }
        guard total > 0 else { return nil }
        return 100 * (Double(deltas[0]) + Double(deltas[1]) + Double(deltas[3])) / total
    }
}
