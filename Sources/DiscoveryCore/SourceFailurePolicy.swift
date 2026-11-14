/// A collector supplies these classifications after its separately reviewed source attempt.
/// This policy does not inspect source payloads, permissions or clocks.
public enum SourceFailure: CaseIterable, Equatable {
    case timeout, permissionDenied, malformedResponse, error
}

public enum SourceAttemptOutcome {
    case success
    case failure(SourceFailure)
}

public enum SourceDisposition: Equatable {
    case ready
    case retryAtNextSample(SourceFailure)
    case disabled(SourceFailure)
}

/// One value per source per session. A disabled instance cannot be reactivated.
/// Decisions only: the caller owns next-sample scheduling, deadlines and worker isolation.
public struct SourceFailurePolicy {
    public private(set) var disposition: SourceDisposition = .ready

    public init() {}

    public mutating func record(_ outcome: SourceAttemptOutcome) {
        // Preserve the original disabling cause even if a late worker result arrives.
        if case .disabled = disposition { return }
        switch outcome {
        case .success:
            disposition = .ready
        case .failure(let failure):
            switch failure {
            case .timeout, .permissionDenied:
                disposition = .disabled(failure)
            case .malformedResponse, .error:
                if case .retryAtNextSample = disposition {
                    disposition = .disabled(failure)
                } else {
                    disposition = .retryAtNextSample(failure)
                }
            }
        }
    }
}
