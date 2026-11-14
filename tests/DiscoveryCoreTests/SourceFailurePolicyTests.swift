import DiscoveryCore

struct SourceFailurePolicyTests {
    func transitionMatrix() {
        for first in SourceFailure.allCases {
            var policy = SourceFailurePolicy()
            expectEqual(policy.disposition, .ready)
            policy.record(.failure(first))
            let immediate = first == .timeout || first == .permissionDenied
            expectEqual(policy.disposition,
                        immediate ? .disabled(first) : .retryAtNextSample(first))
            // Every pair, including mixed malformed/error failures, has a bounded budget.
            for second in SourceFailure.allCases {
                var retry = policy
                retry.record(.failure(second))
                expectEqual(retry.disposition, .disabled(immediate ? first : second))
            }
        }
    }

    func successResetsOnlyActivePolicies() {
        var ready = SourceFailurePolicy()
        ready.record(.success)
        expectEqual(ready.disposition, .ready)
        for first in [SourceFailure.error, .malformedResponse] {
            var policy = SourceFailurePolicy()
            policy.record(.failure(first))
            policy.record(.success)
            expectEqual(policy.disposition, .ready)
            for next in [SourceFailure.error, .malformedResponse] {
                var recovered = policy
                recovered.record(.failure(next))
                expectEqual(recovered.disposition, .retryAtNextSample(next))
                recovered.record(.failure(next))
                expectEqual(recovered.disposition, .disabled(next))
            }
        }
    }

    func disabledIsAbsorbingAndInstancesAreIndependent() {
        for failure in SourceFailure.allCases {
            var policy = SourceFailurePolicy()
            policy.record(.failure(failure))
            policy.record(.failure(failure))
            expectEqual(policy.disposition, .disabled(failure))
            // Late success or subsequent errors cannot revive a disabled source or hide its cause.
            policy.record(.success)
            expectEqual(policy.disposition, .disabled(failure))
            for later in SourceFailure.allCases {
                policy.record(.failure(later))
                expectEqual(policy.disposition, .disabled(failure))
            }
            var otherSource = SourceFailurePolicy()
            otherSource.record(.success)
            expectEqual(otherSource.disposition, .ready)
            var nextSession = SourceFailurePolicy()
            nextSession.record(.failure(.error))
            expectEqual(nextSession.disposition, .retryAtNextSample(.error))
            expectEqual(policy.disposition, .disabled(failure))
        }
    }
}
