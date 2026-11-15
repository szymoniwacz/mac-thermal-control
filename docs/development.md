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

This script compiles the same module, executable and contract cases for **x86_64 macOS 12**, then runs synthetic-only CLI integration checks. It creates artifacts only under ignored `.build/contract-tests/`. Unit tests cover gap/null semantics, zero measurements, finite values, counter resets/overflows, configuration limits, schema fields, capabilities and record/session bounds, plus JSONL envelope recovery. Executable checks cover default refusal, both formats and broken stdout. No test invokes a live source.

## In-memory session envelope recovery

[Goal #13](https://github.com/szymoniwacz/mac-thermal-control/issues/13) adds `SessionReader.read(Data)` to `DiscoveryCore`. There is no CLI reader command or file access. The caller supplies at most 8 MiB; each record is at most 64 KiB including its LF terminator. The reader accepts only newline-terminated JSON objects, verifies schema version 1, a consistent nonempty session ID, contiguous sequences starting at zero, nonempty wall-time strings and finite nondecreasing elapsed time starting at zero. The start inventory must identify the same session and schema. Samples and source-error records may follow; an end record must declare completeness, a termination reason and the correct sample count.

`records` preserves the accepted prefix byte-for-byte. The first malformed line, unsupported version, invalid envelope or oversized record stops recovery; later lines are never stitched over a gap. An unterminated final line is discarded even if its JSON parses. Empty input, missing end, declared incompleteness and any data after an end record are explicitly incomplete. Inputs over the session cap are rejected without retaining a prefix. `issue` is a fixed enum code and never contains input text.

`hasCompleteEnvelope` means only that envelope/framing checks passed and the end declared completeness. Observation values, provenance, timestamps' calendar syntax, payload schemas, source authenticity and hardware safety are **not validated**. Raw records remain untrusted; this API is not a full report decoder. Full typed payload validation and any user-facing file-reading flow remain separate work. Tests cover demo round trips, zero/maximum frames, truncation/corruption, mixed versions/sessions, ordering/timing/end faults, numeric/boolean type confusion, bounds and this payload-validation limitation.

Typechecking is part of both Swift compiler build paths; `-warnings-as-errors` is the SwiftPM compiler-warning gate. There is no separate linter/formatter dependency or command. Shell syntax uses `bash -n scripts/*.sh tests/test-adapter.sh`; whitespace uses `git diff --check`. Existing adapter commands remain separate from product tests.

## Per-source failure policy

[Goal #15](https://github.com/szymoniwacz/mac-thermal-control/issues/15) adds the pure `SourceFailurePolicy` value type. Give each source a separate instance for each session and supply typed `SourceAttemptOutcome` results. Timeout or permission denial produces `.disabled` immediately. The first malformed response or generic error produces `.retryAtNextSample`; any consecutive failure then disables that source. A success before disabling returns to `.ready` and resets the consecutive-failure budget. Disabled instances ignore all later outcomes, including late successes, and preserve the original disabling cause. Only a fresh session policy starts ready again.

These are decisions for a future collector, not enforced source execution or timers. The caller must retain the policy, honor disabling and wait for the next scheduled sample before a permitted retry. The policy does not schedule attempts, parse or classify payloads, change permissions, enforce deadlines, terminate workers, write reports or collect telemetry. Mapping actual source results and integrating scheduling/isolation remain separate reviewed work; this increment does not change CLI behavior. Synthetic tests exercise every failure pair, success resets, late outcomes and source/session independence.

## Sampling schedule policy

[Goal #17](https://github.com/szymoniwacz/mac-thermal-control/issues/17) adds the pure `SamplingSchedule` value type, using the existing bounded `CollectionConfiguration`. A future caller supplies session-relative monotonic elapsed seconds to `poll`. Slots are numbered from one, open at `slot * interval`, and expire when the next slot opens. The last slot remains available through the configured duration, inclusive; a slot exactly at duration may start at that instant. A duration shorter than one interval has no slots. This convention matches the demo's first-sample timing without changing the demo.

Each poll returns at most one start decision plus a bounded range of skipped slot numbers. Late polls skip expired slots; they never replay a backlog. A frame stays in flight until its matching `complete(slot:)` call. Other polls can report missed slots but cannot start overlapping frames. Repeated polls at the same timestamp cannot replay an already started slot. Invalid/backwards internal clock values stop scheduling with `invalidClock`; cancellation and terminal reasons are absorbing. After a stop, completions are ignored. `inFlightSlot` retains the last outstanding token for caller bookkeeping and does not imply that a worker has stopped.

The policy reads no clock and starts no timer, source or worker. It is single-owner state, not a concurrency primitive. The caller must honor its decisions, emit the skipped-slot gaps, manage completion/output and stop workers separately. Duration/cancellation decisions do not cancel native work or enforce the 500 ms source / 900 ms frame budgets. CPU baseline reset, source-failure policy integration, live scheduling, deadlines, isolation and report wiring remain separate work. Synthetic tests cover fractional/exact boundaries, missed slots, busy frames, 600-slot exhaustion, clock faults, cancellation and independent instances; no hardware evidence is claimed.

## Toolchain and CI evidence

Local compiler metadata on 2026-11-14: Apple Swift 5.7.2 (`swiftlang-5.7.2.135.5`), target `x86_64-apple-darwin21.6.0`, SDK 13.1. The installed Command Line Tools lack XCTest and the SwiftPM `PackageDescription` module, so local `swift build`/`swift run` cannot load the manifest. The direct `swiftc` path validates actual source with Swift 5.7; it does not repair or silently certify the local SwiftPM installation. No toolchain was installed or changed.

Product CI checks SwiftPM separately, runs the same contract cases and the direct Intel build/integration checks on `macos-15-intel`. That label is listed as an Intel runner in [GitHub's runner documentation](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) (checked 2026-11-14); the two existing Linux/macOS adapter jobs are retained. A newer runner/compiler supplements local Swift 5.7 checks; it does not prove launch on the target Monterey version or hardware behavior. This goal performs no hardware test.

## Fake-reader public inventory normalization

[Goal #21](https://github.com/szymoniwacz/mac-thermal-control/issues/21) adds `PublicInventory.read(_:using:checkedAt:)`. It accepts an injected `PublicInventoryReader` and performs exactly one typed read of one of seven fixed sysctl fields: model, architecture string, CPU brand, OS build, memory bytes and logical/physical CPU counts. There is **no native reader implementation**, and neither the CLI nor report generator invokes this API. Tests inject synthetic buffers only. The source IDs identify the intended interface, not proof of a real measurement; these test observations are not live telemetry.

The enum fixes selectors and buffer capacities. Strings require a bounded positive returned length, a trailing NUL, no embedded NUL, printable ASCII and nonempty trimmed content. Returned length delimits initialized storage; unused tail bytes are ignored. Intel little-endian integers require the exact eight-byte unsigned memory or four-byte positive signed CPU-count width. Zero/negative inventory integers and malformed buffers yield null gaps. `ObservationValue.unsignedInteger(UInt64)` encodes exact JSON integer tokens without passing through Double; numeric units remain required. Existing fractional/derived measurements retain their Double representation.

Read failures are typed: permission denied and unsupported retain those statuses; insufficient buffer becomes invalid, and generic failures become error. Diagnostics use fixed reason codes with no source dump. A future native shim must map errno and prove actual read-only arguments and memory ownership independently. The reader protocol restricts requests but cannot prove the safety or bounds of a supplied implementation. There is no retry/fallback, deadline, worker isolation, OS-version adapter, persistence or live report wiring here. Existing failure/capability policies still need later integration; no physical-device behavior is certified.

The same product tests cover the fixed field requests, failure/length/type/string bounds, exact integers above 2^53 and through UInt64.max, provenance/null semantics and unchanged CLI refusal. Input validation requires human review and merge, despite the synthetic-only execution path.

## Fake-reader CPU ticks and thermal categories

[Goal #23](https://github.com/szymoniwacz/mac-thermal-control/issues/23) adds the `PublicCPUTicks` and `PublicThermalPressure` normalization boundaries from adopted D-020. Both make exactly one injected read and reject empty check-time metadata before invoking it. Tests supply fake readers only; no native implementation ships and the CLI/report generator does not invoke them. Source IDs describe intended interfaces, not verified measurements. No retry, fallback, scheduling, worker, deadline or policy integration is provided.

CPU success requires exactly four UInt32 counters and a returned count of four **elements**, in user/system/idle/nice order. Each is widened independently to `CPUTicks` UInt64 storage; zero and UInt32.max are valid cumulative counters. `PublicCPUTickResult.success` retains source identity and supplied application read/check time. It is not an activity percentage and has no report serializer. A failed read yields an error/null observation; count/storage mismatch yields invalid/null, with fixed reason codes and no raw data. A generic Mach failure never implies permission denial. Future native code must verify SDK layouts/counts, index order and port ownership independently.

Synthetic handoff tests feed accepted ticks to `CPUActivityDelta`: the first sample, zero total delta and reset produce gaps, while advancing idle ticks with unchanged busy ticks produce a valid 0% interval. These tests do not implement runtime baseline management. A future caller must reset after failures, unavailable sources, skipped frames or sleep-like gaps, and retain the approved cache/freshness limitations.

Thermal input is a fixed typed state: nominal/fair/serious/critical map to unitless categories; unknown/future state yields unverified/null with `thermal_state_unknown`, without retaining its raw number. A future Foundation reader must map known enums and its unknown default explicitly. Even a successful nominal result may come from an unsupported system; it proves no temperature, sensor support, freshness, safe condition or throttling state. Fake tests cover all states, provenance/null JSON, count extremes, failure mapping and independent reader calls without caching.

This implements the adopted validation contract and requires human review/merge under the security policy. OS-version/battery normalization, native adapters and all runtime/device gates remain separate. The CLI remains synthetic-only and phase 1 remains incomplete.

## Remaining implementation

The owner adopted the [Goal #19 public telemetry and isolation design](public-telemetry-adapter-review.md) as D-020 ([decision record](https://github.com/szymoniwacz/mac-thermal-control/issues/1#issuecomment-6897940905)): fixed public calls/fields, power semantics, one same-permission unprivileged worker and bounded protocol/timing/cleanup. It provides process fault isolation, not an OS security sandbox. Start with synthetic/fake sources and one scoped goal at a time; native/IPC security-sensitive changes require human review and human merge. No hardware operation or capture is authorized by adoption.

The [approved R-001 contract](discovery-specification.md) is the target, not a statement that every behavior exists in this increment. Live public-source adapters, native-call review and isolation, secure new-directory JSON/JSONL persistence, actual scheduling/deadlines/cancellation, full payload decoding, overhead measurement and owner-device validation remain future work. The C boundary is deferred until a reviewed native source needs it. Full GPU/fan/temperature/performance coverage remains required or must be reported as explicit gaps; no fallback to privileged or unreviewed sources is allowed.

No privileged operation, SMC write, hardware test or workload is authorized. Later AppleSMC, controller ownership/recovery, workloads, Smart Auto, GUI and optional Ruby Mode retain their separate gates. Development tests and demo output are synthetic software verification only. Roll back this increment through a reviewed forward revert PR; it creates no measurement store or deployed service.
