import Foundation

public enum SessionReadIssue: String {
    case sessionTooLarge, recordTooLarge, truncatedTail, malformedRecord
    case incompatibleSchema, invalidEnvelope, missingEnd, declaredIncomplete, trailingData
}

/// Raw evidence with validated envelopes only. Payloads are not trusted telemetry.
public struct SessionReadResult {
    /// Newline-terminated records, preserved byte-for-byte up to the first failure.
    public let records: [Data]
    public let issue: SessionReadIssue?
    /// Transport/envelope completeness only; not payload validity or source authenticity.
    public var hasCompleteEnvelope: Bool { issue == nil }
}

/// Bounded in-memory recovery. No file access, source calls or CLI input path.
public enum SessionReader {
    private struct Identity: Decodable {
        let schema_version: Int
        let session_id: String
    }

    private struct Envelope: Decodable {
        let schema_version: Int
        let session_id: String
        let sequence: Int
        let type: String
        let wall_time: String
        let elapsed_seconds: Double
        let inventory: Identity?
        let completed_frame_count: Int?
        let complete: Bool?
        let termination_reason: String?
    }

    public static func read(_ data: Data) -> SessionReadResult {
        guard data.count <= DemoReport.maximumOutputBytes else {
            return SessionReadResult(records: [], issue: .sessionTooLarge)
        }
        var records: [Data] = []
        var sessionID: String?
        var elapsed = 0.0
        var frames = 0
        var ended = false
        var endComplete = false
        var start = data.startIndex
        let decoder = JSONDecoder()
        func result(_ issue: SessionReadIssue) -> SessionReadResult {
            SessionReadResult(records: records, issue: issue)
        }
        while start < data.endIndex {
            // Even whitespace after the end record is extra stream data.
            if ended { return result(.trailingData) }
            let newline = data[start...].firstIndex(of: 10)
            let end = newline.map { data.index(after: $0) } ?? data.endIndex
            guard data.distance(from: start, to: end) <= DemoReport.maximumRecordBytes else {
                return result(.recordTooLarge)
            }
            guard let newline = newline else { return result(.truncatedTail) }
            let line = Data(data[start..<newline])
            // Decode identity first so a future schema does not look like a broken v1 record.
            guard let identity = try? decoder.decode(Identity.self, from: line) else {
                return result(.malformedRecord)
            }
            guard identity.schema_version == 1 else { return result(.incompatibleSchema) }
            guard let record = try? decoder.decode(Envelope.self, from: line) else {
                return result(.malformedRecord)
            }
            guard !record.session_id.isEmpty, !record.wall_time.isEmpty,
                  record.sequence == records.count,
                  record.elapsed_seconds.isFinite, record.elapsed_seconds >= elapsed,
                  sessionID == nil || record.session_id == sessionID else {
                return result(.invalidEnvelope)
            }
            if records.isEmpty {
                guard record.type == "session_start", record.elapsed_seconds == 0,
                      let inventory = record.inventory,
                      inventory.session_id == record.session_id else {
                    return result(.invalidEnvelope)
                }
                guard inventory.schema_version == 1 else { return result(.incompatibleSchema) }
                sessionID = record.session_id
            } else {
                switch record.type {
                case "sample": frames += 1
                case "source_error": break
                case "session_end":
                    guard record.completed_frame_count == frames,
                          let complete = record.complete,
                          let reason = record.termination_reason, !reason.isEmpty else {
                        return result(.invalidEnvelope)
                    }
                    ended = true
                    endComplete = complete
                default: return result(.invalidEnvelope)
                }
            }
            records.append(Data(data[start..<end]))
            elapsed = record.elapsed_seconds
            start = end
        }
        guard ended else { return result(.missingEnd) }
        guard endComplete else { return result(.declaredIncomplete) }
        return SessionReadResult(records: records, issue: nil)
    }
}
