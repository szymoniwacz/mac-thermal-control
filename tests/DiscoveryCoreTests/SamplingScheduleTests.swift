import DiscoveryCore

struct SamplingScheduleTests {
    func boundariesAndNoCatchUp() throws {
        var schedule = SamplingSchedule(configuration: try CollectionConfiguration(
            intervalSeconds: 1.5, durationSeconds: 6))
        expectEqual(schedule.poll(elapsed: 0).action, .wait(untilElapsed: 1.5))
        expectEqual(schedule.poll(elapsed: 1.5.nextDown).action, .wait(untilElapsed: 1.5))
        let late = schedule.poll(elapsed: 4.5)
        expectEqual(late.skippedSlots, 1..<3)
        expectEqual(late.action, .start(slot: 3, scheduledElapsed: 4.5))
        expectTrue(schedule.complete(slot: 3))
        // Same timestamp cannot start a catch-up frame, even after completion.
        expectEqual(schedule.poll(elapsed: 4.5).action, .wait(untilElapsed: 6))
        expectEqual(schedule.poll(elapsed: 6).action, .start(slot: 4, scheduledElapsed: 6))
        expectTrue(schedule.complete(slot: 4))
        expectEqual(schedule.poll(elapsed: 6).action, .stopped(.scheduleExhausted))
        schedule.cancel()
        expectEqual(schedule.poll(elapsed: .nan).action, .stopped(.scheduleExhausted))

        var fractional = SamplingSchedule(configuration: try CollectionConfiguration(
            intervalSeconds: 1.1, durationSeconds: 5))
        let boundary = 3 * 1.1
        let before = fractional.poll(elapsed: boundary.nextDown)
        expectEqual(before.skippedSlots, 1..<2)
        expectEqual(before.action, .start(slot: 2, scheduledElapsed: 2 * 1.1))
        expectTrue(fractional.complete(slot: 2))
        expectEqual(fractional.poll(elapsed: boundary).action,
                    .start(slot: 3, scheduledElapsed: boundary))
    }

    func busyFramesAndMissedSlots() throws {
        var schedule = SamplingSchedule(configuration: try CollectionConfiguration(durationSeconds: 5))
        expectEqual(schedule.poll(elapsed: 1).action, .start(slot: 1, scheduledElapsed: 1))
        expectEqual(schedule.poll(elapsed: 2).action, .inFlight(slot: 1))
        expectFalse(schedule.complete(slot: 2))
        let busy = schedule.poll(elapsed: 4.2)
        expectEqual(busy.action, .inFlight(slot: 1))
        expectEqual(busy.skippedSlots, 2..<4)
        expectEqual(schedule.poll(elapsed: 4.2).skippedSlots, 4..<4)
        expectTrue(schedule.complete(slot: 1))
        expectFalse(schedule.complete(slot: 1))
        expectEqual(schedule.poll(elapsed: 4.2).action, .start(slot: 4, scheduledElapsed: 4))
        expectFalse(schedule.complete(slot: 1))
        expectEqual(schedule.poll(elapsed: 5).action, .inFlight(slot: 4))
        expectTrue(schedule.complete(slot: 4))
        expectEqual(schedule.poll(elapsed: 5).action, .start(slot: 5, scheduledElapsed: 5))
    }

    func durationAndFrameBounds() throws {
        var zero = SamplingSchedule(configuration: try CollectionConfiguration(
            intervalSeconds: 60, durationSeconds: 1))
        expectEqual(zero.poll(elapsed: 0).action, .stopped(.scheduleExhausted))
        var maximum = SamplingSchedule(configuration: try CollectionConfiguration(durationSeconds: 600))
        for slot in 1...600 {
            let poll = maximum.poll(elapsed: Double(slot))
            expectTrue(poll.skippedSlots.isEmpty)
            expectEqual(poll.action, .start(slot: slot, scheduledElapsed: Double(slot)))
            expectTrue(maximum.complete(slot: slot))
        }
        expectEqual(maximum.poll(elapsed: 600).action, .stopped(.scheduleExhausted))

        var jumped = SamplingSchedule(configuration: try CollectionConfiguration(durationSeconds: 600))
        let end = jumped.poll(elapsed: Double.greatestFiniteMagnitude)
        expectEqual(end.action, .stopped(.durationElapsed))
        expectEqual(end.skippedSlots, 1..<601)
        expectTrue(jumped.poll(elapsed: 601).skippedSlots.isEmpty)
        // Last slot stays available to the end even when duration is not a multiple.
        var tail = SamplingSchedule(configuration: try CollectionConfiguration(
            intervalSeconds: 2, durationSeconds: 5))
        expectEqual(tail.poll(elapsed: 5).action, .start(slot: 2, scheduledElapsed: 4))
        expectEqual(tail.poll(elapsed: 5.nextUp).action, .stopped(.durationElapsed))
        expectFalse(tail.complete(slot: 2))
    }

    func cancellationClockFaultsAndIsolation() throws {
        let config = try CollectionConfiguration(durationSeconds: 5)
        for invalid in [Double.nan, .infinity, -.infinity, -1, 1.0.nextDown] {
            var schedule = SamplingSchedule(configuration: config)
            _ = schedule.poll(elapsed: 1)
            expectEqual(schedule.poll(elapsed: invalid).action, .stopped(.invalidClock))
            expectFalse(schedule.complete(slot: 1))
            schedule.cancel()
            expectEqual(schedule.poll(elapsed: 2).action, .stopped(.invalidClock))
        }
        for started in [false, true] {
            var cancelled = SamplingSchedule(configuration: config)
            if started { _ = cancelled.poll(elapsed: 1) }
            cancelled.cancel()
            cancelled.cancel()
            expectEqual(cancelled.poll(elapsed: 2).action, .stopped(.cancelled))
            expectFalse(cancelled.complete(slot: 1))
            expectEqual(cancelled.poll(elapsed: .nan).action, .stopped(.cancelled))
        }
        var original = SamplingSchedule(configuration: config)
        var copy = original
        _ = copy.poll(elapsed: 4)
        copy.cancel()
        expectEqual(original.poll(elapsed: 1).action, .start(slot: 1, scheduledElapsed: 1))
        var freshSession = SamplingSchedule(configuration: config)
        expectEqual(freshSession.poll(elapsed: 0).action, .wait(untilElapsed: 1))
    }
}
