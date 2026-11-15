public enum SamplingStopReason: Equatable {
    case scheduleExhausted, durationElapsed, cancelled, invalidClock
}

public enum SamplingAction: Equatable {
    case wait(untilElapsed: Double)
    case start(slot: Int, scheduledElapsed: Double)
    case inFlight(slot: Int)
    case stopped(SamplingStopReason)
}

public struct SamplingPoll {
    public let action: SamplingAction
    /// One-based scheduled slots skipped by this poll, never silently discarded.
    public let skippedSlots: Range<Int>
}

/// Pure, single-owner scheduling policy. Supply session-relative monotonic seconds.
/// No clocks, timers, source execution, worker cancellation or report integration.
public struct SamplingSchedule {
    private let configuration: CollectionConfiguration
    private var nextSlot = 1
    private var lastElapsed = 0.0
    public private(set) var inFlightSlot: Int?
    public private(set) var stopReason: SamplingStopReason?

    public init(configuration: CollectionConfiguration) {
        self.configuration = configuration
    }

    /// Each slot opens at index * interval and expires when the next opens.
    /// The last slot stays available through duration, including an exact-end slot.
    /// Polling never starts more than one frame; callers must honor the decision.
    public mutating func poll(elapsed: Double) -> SamplingPoll {
        let firstSkipped = nextSlot
        func result(_ action: SamplingAction, _ end: Int) -> SamplingPoll {
            SamplingPoll(action: action, skippedSlots: firstSkipped..<end)
        }
        if let reason = stopReason { return result(.stopped(reason), nextSlot) }
        guard elapsed.isFinite, elapsed >= lastElapsed else {
            stopReason = .invalidClock
            return result(.stopped(.invalidClock), nextSlot)
        }
        lastElapsed = elapsed
        let count = configuration.frameCount
        // Bounded by 600; compare computed boundaries instead of rounding elapsed/interval.
        while nextSlot <= count {
            let expired = elapsed > configuration.durationSeconds ||
                (nextSlot < count && elapsed >= due(nextSlot + 1))
            if !expired { break }
            nextSlot += 1
        }
        let endSkipped = nextSlot
        if elapsed > configuration.durationSeconds {
            stopReason = .durationElapsed
            return result(.stopped(.durationElapsed), endSkipped)
        }
        if let slot = inFlightSlot { return result(.inFlight(slot: slot), endSkipped) }
        guard nextSlot <= count else {
            stopReason = .scheduleExhausted
            return result(.stopped(.scheduleExhausted), endSkipped)
        }
        let scheduled = due(nextSlot)
        guard elapsed >= scheduled else {
            return result(.wait(untilElapsed: scheduled), endSkipped)
        }
        let slot = nextSlot
        nextSlot += 1
        inFlightSlot = slot
        return result(.start(slot: slot, scheduledElapsed: scheduled), endSkipped)
    }

    /// A stale or mismatched completion cannot release another frame. Late completion
    /// after stopping is ignored; physical worker lifecycle is the caller's responsibility.
    @discardableResult
    public mutating func complete(slot: Int) -> Bool {
        guard stopReason == nil, inFlightSlot == slot else { return false }
        inFlightSlot = nil
        return true
    }

    public mutating func cancel() {
        if stopReason == nil { stopReason = .cancelled }
    }

    private func due(_ slot: Int) -> Double {
        Double(slot) * configuration.intervalSeconds
    }
}
