import Foundation
import DiscoveryCore

struct SessionReaderTests {
    private func fixture() throws -> [[String: Any]] {
        try DemoReport.render(format: .jsonl, configuration: CollectionConfiguration(),
                              sessionID: "fixture").split(separator: 10).map {
            try unwrap(JSONSerialization.jsonObject(with: Data($0)) as? [String: Any])
        }
    }

    private func stream(_ records: [[String: Any]]) throws -> Data {
        var data = Data()
        for record in records {
            data.append(try JSONSerialization.data(withJSONObject: record, options: [.sortedKeys]))
            data.append(10)
        }
        return data
    }

    func roundTrip() throws {
        for config in [try CollectionConfiguration(),
                       try CollectionConfiguration(intervalSeconds: 60, durationSeconds: 1),
                       try CollectionConfiguration(durationSeconds: 600)] {
            let data = try DemoReport.render(format: .jsonl, configuration: config)
            let result = SessionReader.read(data)
            expectTrue(result.hasCompleteEnvelope)
            expectNil(result.issue)
            expectEqual(result.records.count, config.frameCount + 2)
            expectEqual(result.records.reduce(into: Data()) { $0.append($1) }, data)
        }
    }

    func truncationAndCorruption() throws {
        let data = try stream(fixture())
        let completeLines = data.split(separator: 10).map { Data($0) + Data([10]) }
        expectEqual(SessionReader.read(Data()).issue, .missingEnd)
        for count in 1..<completeLines.count {
            let prefix = completeLines.prefix(count).reduce(into: Data()) { $0.append($1) }
            let missing = SessionReader.read(prefix)
            expectEqual(missing.issue, .missingEnd)
            expectEqual(missing.records.count, count)
            // A syntactically valid last JSON object without LF is still uncommitted.
            let partial = SessionReader.read(prefix + Data(completeLines[count].dropLast()))
            expectEqual(partial.issue, .truncatedTail)
            expectEqual(partial.records, missing.records)
            let corrupt = SessionReader.read(prefix + Data("{broken}\n".utf8) + data)
            expectEqual(corrupt.issue, .malformedRecord)
            expectEqual(corrupt.records, missing.records)
        }
        for suffix in [Data([10]), Data("partial".utf8), data] {
            let extra = SessionReader.read(data + suffix)
            expectEqual(extra.issue, .trailingData)
            expectFalse(extra.hasCompleteEnvelope)
            expectEqual(extra.records.count, completeLines.count)
        }
        for line in ["\n", "[]\n", "null\n", "{\"schema_version\":true,\"session_id\":\"x\"}\n",
                     "{\"schema_version\":1,\"session_id\":\"x\",\"elapsed_seconds\":1e999}\n"] {
            expectEqual(SessionReader.read(Data(line.utf8)).issue, .malformedRecord)
        }
        expectEqual(SessionReader.read(Data([0xff, 10])).issue, .malformedRecord)
    }

    func versionsAndEnvelopeFailures() throws {
        let original = try fixture()
        for version in [0, 2, -1] {
            // No v1-only fields are required to recognize an incompatible schema.
            let future = try stream([["schema_version": version, "session_id": "fixture"]])
            let result = SessionReader.read(future)
            expectEqual(result.issue, .incompatibleSchema)
            expectTrue(result.records.isEmpty)
            var mixed = original
            mixed[1]["schema_version"] = version
            expectEqual(SessionReader.read(try stream(mixed)).issue, .incompatibleSchema)
            var nested = original
            var inventory = try unwrap(nested[0]["inventory"] as? [String: Any])
            inventory["schema_version"] = version
            nested[0]["inventory"] = inventory
            expectEqual(SessionReader.read(try stream(nested)).issue, .incompatibleSchema)
        }
        let changes: [(Int, String, Any)] = [
            (0, "type", "sample"), (0, "sequence", 1), (0, "elapsed_seconds", -1),
            (0, "elapsed_seconds", 1), (0, "session_id", ""), (1, "session_id", "other"),
            (1, "sequence", 0), (1, "sequence", 3), (1, "type", "future_record"),
            (1, "type", "session_start"), (2, "elapsed_seconds", 0.5),
            (2, "wall_time", ""), (3, "completed_frame_count", 9),
            (3, "termination_reason", "")
        ]
        for (index, key, value) in changes {
            var records = original
            records[index][key] = value
            let result = SessionReader.read(try stream(records))
            expectEqual(result.issue, .invalidEnvelope, "\(index) \(key)")
            expectEqual(result.records.count, index)
            expectFalse(result.hasCompleteEnvelope)
        }
        for (index, key, value) in [(1, "sequence", true as Any),
                                     (1, "sequence", 1.5 as Any),
                                     (1, "elapsed_seconds", false as Any),
                                     (3, "complete", 1 as Any),
                                     (3, "completed_frame_count", true as Any)] {
            var records = original
            records[index][key] = value
            expectEqual(SessionReader.read(try stream(records)).issue, .malformedRecord)
        }
        var records = original
        records[3]["complete"] = false
        let incomplete = SessionReader.read(try stream(records))
        expectEqual(incomplete.issue, .declaredIncomplete)
        expectEqual(incomplete.records.count, 4)
        expectFalse(incomplete.hasCompleteEnvelope)
        records[3].removeValue(forKey: "complete")
        expectEqual(SessionReader.read(try stream(records)).issue, .invalidEnvelope)
    }

    func boundsAndPayloadLimitations() throws {
        let original = try fixture()
        let first = try stream([original[0]])
        let large = Data(repeating: 32, count: DemoReport.maximumRecordBytes)
        expectEqual(SessionReader.read(first + large + Data([10])).issue, .recordTooLarge)
        expectEqual(SessionReader.read(large + Data([32])).issue, .recordTooLarge)
        expectEqual(SessionReader.read(Data(repeating: 32,
            count: DemoReport.maximumOutputBytes + 1)).issue, .sessionTooLarge)
        expectEqual(SessionReader.read(Data(repeating: 32,
            count: DemoReport.maximumOutputBytes)).issue, .recordTooLarge)
        // A record exactly at the inclusive byte cap is accepted (including LF).
        let padding = DemoReport.maximumRecordBytes - first.count
        let atLimit = Data(repeating: 32, count: padding) + first
        let remainder = try stream(Array(original.dropFirst()))
        let accepted = SessionReader.read(atLimit + remainder)
        expectTrue(accepted.hasCompleteEnvelope)
        expectEqual(accepted.records.first, atLimit)
        var sourceError = original[1]
        sourceError["type"] = "source_error"
        sourceError["sequence"] = 2
        var records = original
        records.insert(sourceError, at: 2)
        records[3]["sequence"] = 3
        records[4]["sequence"] = 4
        // Envelope completeness is intentionally separate from observation validation.
        records[1]["observations"] = "not valid telemetry"
        expectTrue(SessionReader.read(try stream(records)).hasCompleteEnvelope)
    }
}
