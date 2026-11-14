import Foundation

// The local Swift 5.7 Command Line Tools omit XCTest. This small runner keeps
// the same deterministic contract cases executable locally and in macOS CI.
var failureCount = 0

private func check(_ condition: Bool, _ message: String, file: StaticString, line: UInt) {
    if !condition {
        failureCount += 1
        print("FAIL \(file):\(line): \(message)")
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "",
                              file: StaticString = #filePath, line: UInt = #line) {
    check(actual == expected, "\(actual) != \(expected) \(message)", file: file, line: line)
}

func expectTrue(_ condition: Bool, file: StaticString = #filePath, line: UInt = #line) {
    check(condition, "expected true", file: file, line: line)
}

func expectFalse(_ condition: Bool, file: StaticString = #filePath, line: UInt = #line) {
    check(!condition, "expected false", file: file, line: line)
}

func expectNil<T>(_ value: T?, file: StaticString = #filePath, line: UInt = #line) {
    check(value == nil, "expected nil", file: file, line: line)
}

func expectLessThanOrEqual<T: Comparable>(_ actual: T, _ limit: T,
                                         file: StaticString = #filePath, line: UInt = #line) {
    check(actual <= limit, "value exceeds bound", file: file, line: line)
}

func expectThrowsError<T>(_ expression: @autoclosure () throws -> T,
                          file: StaticString = #filePath, line: UInt = #line) {
    do {
        _ = try expression()
        check(false, "expected error", file: file, line: line)
    } catch {}
}

struct MissingFixtureValue: Error {}

func unwrap<T>(_ value: T?) throws -> T {
    guard let value = value else { throw MissingFixtureValue() }
    return value
}
