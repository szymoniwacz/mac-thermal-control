import DiscoveryCore
import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

// Turn a closed stdout pipe into a caught write error and the documented exit 3.
signal(SIGPIPE, SIG_IGN)
let result = Command.run(arguments: Array(CommandLine.arguments.dropFirst()))
do {
    if !result.output.isEmpty { try FileHandle.standardOutput.write(contentsOf: result.output) }
    if !result.diagnostic.isEmpty {
        try FileHandle.standardError.write(contentsOf: Data(result.diagnostic.utf8))
    }
    exit(result.exitCode)
} catch {
    // A broken output stream is an incomplete report, never successful discovery.
    exit(3)
}
