import Foundation

public struct CommandResult {
    public let output: Data
    public let diagnostic: String
    public let exitCode: Int32
}

/// No option can enable live collection in this increment.
public enum Command {
    public static let usage = """
    Usage: mac-thermal-control --demo [--format json|jsonl] [--interval SECONDS] [--duration SECONDS]
           mac-thermal-control --help
    Synthetic fixtures only; no hardware access. Live discovery is not implemented.
    Defaults: jsonl, simulated interval 1 second, simulated duration 2 seconds.
    Bounds: interval 1–60 seconds; duration 1–600 seconds. Demo does not wait in real time.
    """

    public static func run(arguments: [String]) -> CommandResult {
        if arguments == ["--help"] {
            return CommandResult(output: Data((usage + "\n").utf8), diagnostic: "", exitCode: 0)
        }
        guard arguments.contains("--demo") else {
            return failure("Live discovery is unavailable. Use --demo for synthetic fixtures only.")
        }
        var seen = Set<String>()
        var format = OutputFormat.jsonl
        var interval = 1.0
        var duration = 2.0
        var index = 0
        while index < arguments.count {
            let option = arguments[index]
            guard seen.insert(option).inserted else { return failure("Duplicate option.") }
            index += 1
            if option == "--demo" { continue }
            guard ["--format", "--interval", "--duration"].contains(option),
                  index < arguments.count else { return failure("Invalid option or missing value.") }
            let value = arguments[index]
            index += 1
            switch option {
            case "--format":
                guard let parsed = OutputFormat(rawValue: value) else { return failure("Invalid format.") }
                format = parsed
            case "--interval":
                guard let parsed = Double(value) else { return failure("Invalid interval.") }
                interval = parsed
            default:
                guard let parsed = Double(value) else { return failure("Invalid duration.") }
                duration = parsed
            }
        }
        do {
            let config = try CollectionConfiguration(intervalSeconds: interval, durationSeconds: duration)
            return CommandResult(output: try DemoReport.render(format: format, configuration: config),
                                 diagnostic: "Synthetic demo only. No hardware accessed.\n", exitCode: 0)
        } catch ContractError.invalidConfiguration {
            return failure("Invalid collection bounds.")
        } catch {
            return CommandResult(output: Data(), diagnostic: "Report serialization failed.\n", exitCode: 3)
        }
    }

    private static func failure(_ message: String) -> CommandResult {
        // Do not echo user-supplied arguments, paths or other potentially identifying strings.
        CommandResult(output: Data(), diagnostic: message + "\n" + usage + "\n", exitCode: 2)
    }
}
