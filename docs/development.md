# Development and fixture-only CLI

Goal #11 introduces the reusable `DiscoveryCore` module and `mac-thermal-control` executable. The CLI currently supports **synthetic fixtures only**, with no hardware source, native telemetry/SMC call, network access, helper, local report persistence or live sampling scheduler. Default invocation refuses collection. The synthetic timestamps, CPU values and capability gaps cannot establish target compatibility, fan/sensor health, overhead, throttling or safety. Neither slice A nor phase 1 is complete.

## Build and tests

Use an existing Swift 5.7-or-later development toolchain and Python 3 for the executable smoke checks. No third-party package or install step is required by this increment. SwiftPM's [manifest/platform declarations](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html) specify tools version 5.7 and macOS 12 minimum deployment. Run from the repository root:

```sh
swift build -Xswiftc -warnings-as-errors
swift run --skip-build ContractTests
swift run --skip-build mac-thermal-control --demo --format json
swift run --skip-build mac-thermal-control --demo --format jsonl
```

The demo defaults to two simulated seconds, at a one-second interval, and does not sleep or collect data. `--interval` accepts finite values from 1 to 60 seconds; `--duration` accepts finite values from 1 to 600 seconds. It emits at most 600 sample frames plus start/end records. These options simulate timing, not a real capture. Diagnostics go to stderr. The JSON inventory identifies all live sources as `not_implemented`; JSONL adds synthetic CPU deltas and explicit gaps. Schema version 1, a fresh random session ID and `configuration.mode: synthetic_demo` identify every session.

The tests intentionally use a small dependency-free runner, rather than XCTest, to support Apple's partial Command Line Tools installations. Failures produce a nonzero exit status. `swift test` is not the project test command.

For an Intel Mac with `swiftc` but an incomplete SwiftPM installation, the supported direct build/test path is:

```sh
bash scripts/test-product.sh
.build/contract-tests/mac-thermal-control --demo --format jsonl
```

This script compiles the same module, executable and fifteen contract cases for **x86_64 macOS 12**, then runs synthetic-only CLI integration checks. It creates artifacts only under ignored `.build/contract-tests/`. Unit tests cover gap/null semantics, zero measurements, finite values, counter resets/overflows, configuration limits, schema fields, capabilities and record/session bounds. Executable checks cover default refusal, both formats and broken stdout. No test invokes a live source.

Typechecking is part of both Swift compiler build paths; `-warnings-as-errors` is the SwiftPM compiler-warning gate. There is no separate linter/formatter dependency or command. Shell syntax uses `bash -n scripts/*.sh tests/test-adapter.sh`; whitespace uses `git diff --check`. Existing adapter commands remain separate from product tests.

## Toolchain and CI evidence

Local compiler metadata on 2026-11-14: Apple Swift 5.7.2 (`swiftlang-5.7.2.135.5`), target `x86_64-apple-darwin21.6.0`, SDK 13.1. The installed Command Line Tools lack XCTest and the SwiftPM `PackageDescription` module, so local `swift build`/`swift run` cannot load the manifest. The direct `swiftc` path validates actual source with Swift 5.7; it does not repair or silently certify the local SwiftPM installation. No toolchain was installed or changed.

Product CI checks SwiftPM separately, runs the same contract cases and the direct Intel build/integration checks on `macos-15-intel`. That label is listed as an Intel runner in [GitHub's runner documentation](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) (checked 2026-11-14); the two existing Linux/macOS adapter jobs are retained. A newer runner/compiler supplements local Swift 5.7 checks; it does not prove launch on the target Monterey version or hardware behavior. This goal performs no hardware test.

## Remaining implementation

The [approved R-001 contract](discovery-specification.md) is the target, not a statement that every behavior exists in this increment. Live public-source adapters, native-call review and isolation, secure new-directory JSON/JSONL persistence, actual scheduling/deadlines/cancellation, schema-reading/version rejection, overhead measurement and owner-device validation remain future work. The C boundary is deferred until a reviewed native source needs it. Full GPU/fan/temperature/performance coverage remains required or must be reported as explicit gaps; no fallback to privileged or unreviewed sources is allowed.

No privileged operation, SMC write, hardware test or workload is authorized. Later AppleSMC, controller ownership/recovery, workloads, Smart Auto, GUI and optional Ruby Mode retain their separate gates. Development tests and demo output are synthetic software verification only. Roll back this increment through a reviewed forward revert PR; it creates no measurement store or deployed service.
