# Read-only discovery specification — R-001

Prepared for [Goal #9](https://github.com/szymoniwacz/mac-thermal-control/issues/9), 2026-11-14. **Owner-approved: R-001 1: A; 2: Y**, recorded in [Project #1](https://github.com/szymoniwacz/mac-thermal-control/issues/1#issuecomment-6879220276). Public, unprivileged telemetry first and the schema/minimization/bounds/failure/validation contract below are accepted. Exact native calls and target compatibility still require review. This approval authorizes no privileged operations, SMC writes, hardware tests or workloads.

Goal #11 implements only the reusable report core and an explicitly synthetic CLI demo. Live public adapters, secure session persistence, real scheduling/deadlines and device validation remain unimplemented; neither slice A nor phase 1 is complete. See [development commands and limitations](development.md).

The [requirements](../.ai/docs/project-requirements.md) remain authoritative for the product outcome and AC-01–AC-06. The [source investigation](monterey-telemetry-research.md) supplies interface evidence and its limitations. This specification bounds the next implementation slice; it does not narrow the final discovery deliverable or certify Monterey compatibility.

## Approved implementation sequence

**A — owner-approved:** build the real Swift/Foundation CLI scaffold, serialization, scheduling and fixture tests with public, unprivileged system sources first. Explicitly report fan, temperature, GPU and performance gaps. Then prepare a separate AppleSMC read-adapter review and implementation goal. The first slice is useful inventory/passive context, but cannot complete phase 1 or demonstrate fan/sensor health.

**B — alternative not selected:** include a reviewed AppleSMC read adapter in the first implementation slice. This can yield fan/temperature evidence sooner, but requires a larger native-interface, ABI, license and cancellation review before any driver access. It still cannot guarantee target coverage or authorize privilege elevation.

**Other:** request a different scope or further research. Neither option allows writes, arbitrary driver commands, blind key sweeps, workloads, control helpers, background installation or automatic uploads. Source failure never triggers escalation or fallback to an unreviewed source.

### Build compatibility proposal

Use SwiftPM, Foundation and OS frameworks, without third-party packages for slice A. Propose Swift 5.7-compatible source and an explicit x86_64 macOS 12 deployment target. Exact compiler, SDK and CI images must be recorded and verified in the scaffold goal before handoff; no install or downgrade is requested here. Existing installed target-Mac tools must be identified by the owner before a hardware build/run procedure is finalized.

Apple's [Xcode 14.2 notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-14_2-release-notes) document Swift 5.7, SDK 13.1 and a Monterey 12.5-or-later host requirement (rechecked 2026-11-14). This is a historical compatibility candidate, not a recommendation to install an old toolchain. Compiler host, SDK, deployment target, architecture and API availability require separate checks. Modern CI compilation cannot prove launch or hardware behavior on Monterey. No GUI framework or SMC dependency is selected.

## Source and capability plan

The capability plan is accepted for staged implementation; exact source calls remain candidates; interface provenance and unresolved restrictions are in the investigation. Each expected capability must appear in the report even when not implemented or unavailable. API presence alone does not establish reliable target data.

| Capability | Slice A candidate | Evidence limit / explicit gap |
|---|---|---|
| Model, OS/build, memory, CPU model/count | Narrow read-only system-property allowlist and Foundation | Validate exact fields and API availability; never dump all properties |
| CPU activity | Mach CPU tick deltas | First observation is insufficient; actual elapsed time and discontinuities matter; no throughput/frequency/throttling inference |
| Thermal pressure | Foundation thermal state | System category only; neither degrees Celsius nor proof of safe temperature; unknown future enum values stay unverified |
| AC/battery context | Selected IOKit power-source fields | AC/battery/unknown only initially; no battery identifiers or unfiltered dictionaries |
| GPU inventory/activity | No adopted source in slice A | `not_implemented`; model alone never supplies a GPU configuration or utilization |
| Fan count, identity, RPM, readable bounds/mode/target | Later separately reviewed AppleSMC adapter | `not_implemented`; no fabricated empty inventory implying no fans; readable bounds never become verified limits |
| Numeric temperatures and trends | Later reviewed sensor source and mappings | `not_implemented`; retain raw identity/mapping uncertainty when eventually supported; never equate CPU PECI and CPU die |
| Live CPU/GPU frequency, power, performance limits | No adopted source in slice A | `not_implemented`; no automatic powermetrics, pmset or private IOReport invocation |

Apple documents [thermalState](https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.property) as the system thermal-state property (rechecked 2026-11-14). Its practical reliability on the target remains unverified. The remaining candidates inherit the pinned research's provenance and limitations and require exact call-level review during implementation.

## Approved output contract for schema version 1

Write a JSON inventory and JSONL stream to an explicit, newly created local session directory. Refuse existing paths and symlinks rather than overwrite reports. Propose owner-only directory/file permissions. No default output to a shared directory, remote sink, compression/upload or hidden retention cleanup. Logs to stderr use bounded error codes/messages without raw source dumps or user paths. The owner chooses sharing and deletion.

The JSON inventory contains `schema_version`, random session ID, application/build version, collection configuration, observed allowlisted inventory and a complete capability table. The ID is generated per run and is unrelated to a device identifier. Record approved source IDs, interface/revision evidence and limitations. Every stream record contains schema/session IDs and a sequence number; record types are `session_start`, `sample`, `source_error` and `session_end`. Version 1 readers reject incompatible versions explicitly.

A sample includes UTC wall time, monotonic elapsed time, actual interval and observations. Wall-clock adjustments never reorder elapsed timing. An observation identifies the signal, source, status, unit, value, observation time, method (`direct` or `derived`) and mapping confidence where relevant. Derived values also identify inputs and calculation/window. Preserve per-source timing; collection completion time is not every source's measurement time.

| Status | Meaning / value rule |
|---|---|
| `ok` | Valid observation; finite numeric or typed categorical value; zero allowed only if actually measured/derived |
| `not_implemented` | Adapter intentionally absent in this slice; value null, reason required |
| `unsupported` | Reviewed source reports capability absent on this platform; value null |
| `missing` | Expected field absent in a successful response; value null |
| `permission_denied` | Access refused; value null; no automatic elevation/retry |
| `invalid` | Wrong type/length, nonfinite value, malformed or unusable sample; value null |
| `unverified` | Semantics or physical mapping not established; no normalized measurement; bounded raw representation only after separate field review |
| `stale` | Prior value exceeded its validity window; current value null; prior record remains historical |
| `timeout` / `error` | Deadline expired / other source failure; value null; bounded reason required |

Unavailable observations use a check timestamp, not a fabricated measurement timestamp. Units are explicit (for example bytes, percent, RPM or degrees Celsius); categorical values declare no physical unit. Unknown is never zero or nominal. No NaN/Infinity in JSON. Unimplemented fan/sensor capabilities remain distinguishable from successfully queried empty lists. Unverified raw values are excluded from slice A.

Proposed persisted fields are limited to the inventory/capability and timing/observation fields above, architecture, CPU counts/model and toolchain/app versions. Exclude serials, hardware UUIDs, host/account names, MAC/IP addresses, network details, process lists/arguments, environment variables, free-text notes, file paths and raw registry/source/error dumps. Review any new field before persistence. No credentials are needed.

## Collection bounds and failure handling

These are approved software collection limits, **not thermal safety thresholds**:

- Default 1-second interval and 60-second session; permit intervals from 1 to 60 seconds and duration from 1 to 600 seconds. Reject invalid/nonfinite values. At most 600 sample frames, with inventory separate; no busy-loop retries or overlapping samples.
- Total output cap 8 MiB per session, including inventory, stream and termination record; reserve space for `session_end` before accepting another record. Maximum serialized record 64 KiB; pending queue at most two records. On size/disk/serialization failure, stop visibly; never silently drop or invent samples. Storage bounds do not depend on free disk estimates alone.
- Proposed source deadline 500 ms and total sample budget 900 ms, measured with a monotonic clock. Skip missed deadlines and report gaps; do not run catch-up bursts. Disable a source for the session after timeout, denial or repeated malformed replies; a transient generic error permits one retry at the next scheduled sample, then disables on another failure. Capability state records the reason.
- Blocking native calls require a separately killable collector process and bounded parent IPC, or must remain unavailable until that design is proven. A timer cannot cancel synchronous kernel work. Parent termination must remain bounded even if worker termination/reaping is delayed; record that uncertainty. No claim of guaranteed kernel-call cancellation.
- On cancellation, stop scheduling and preserve completed records. Write termination reason, completed frame count, gaps and completeness if output is writable. Abrupt termination or disk failure can leave no end record or a trailing partial line; readers retain only complete records and label the session incomplete. Inventory publication uses a temporary file in the selected directory with final rename after successful serialization; never replace an existing destination.
- After sleep/wake, a counter discontinuity or an interval exceeding twice the requested interval, emit a gap and reset CPU-delta/trend baselines. The first valid CPU counter sample after reset cannot yield an activity percentage. Do not carry old measurements forward as fresh data.
- Measure parent plus collector-worker CPU time and aggregate resident memory as collection-overhead evidence where available; account for workers that exit before session end. Proposed owner-validation budgets: mean CPU below 5% of one logical core over a session and peak memory below 64 MiB, with method/platform limitations recorded. These are provisional acceptance budgets, not observed performance; failed budgets require adjustment/review before broader capture. Generate no workload to measure them.

Proposed exit statuses: 0 for bounded normal completion with a valid report (capability gaps may remain); 2 for invalid arguments/output initialization failure; 3 for an incomplete session/source infrastructure failure; 130 for user interruption. Capability gaps are visible in the report and summary even with status 0; none imply phase completion. Tests must distinguish source-local gaps from session-wide infrastructure failures.

## Validation and phase acceptance

| Criterion | First slice verification | Remaining target/phase evidence |
|---|---|---|
| AC-01 | Fixture inventory, complete capability table, JSON/JSONL and CLI flow | Owner runs the reviewed executable on actual Mac/OS; fan/temperature/performance coverage remains open after slice A |
| AC-02 | Review native calls/dependencies; no setters, arbitrary commands, external telemetry tools, privileged/control helper or network path; a bounded unprivileged collector worker is permitted for isolation; fixture sources cannot touch hardware | Review each eventual SMC transaction, selector, opcode and ABI before owner access; RPM stability is not proof of no writes |
| AC-03 | Golden/schema cases for every status, real zero, malformed/nonfinite values, provenance, units and first-sample CPU delta | Validate mappings, per-fan identity and actual availability; readable bounds stay separate from verified safe limits |
| AC-04 | Fake-clock tests for duration/frame/output caps, sequence, timing, counter reset, overhead fields and schema version rejection | Repeated owner-run bounded passive sessions; actual toolchain/SDK/architecture/API availability and overhead evidence |
| AC-05 | Inject denial, unsupported/missing fields, malformed replies, blocked worker, timeout, cancellation, sleep-like gaps, disk full, broken output and truncated JSONL | Owner interruption/sleep-wake checks only after reviewed build; preserve partial evidence and honest source gaps |
| AC-06 | Report explicitly states coverage and incomplete phase/safety evidence | Owner reviews critical gaps before safety assessment; no workload/control gate passes from CLI success |

The scaffold goal must record real setup/build/run/test/typecheck/lint commands (or explain inapplicable categories), product CI and a test path that uses fixtures without querying real hardware. Keep existing Linux/macOS adapter checks. Hardware-backed CLI execution remains owner-run; no automatic device capture during build, tests or CI. Actual hardware testing is separate evidence from fixture correctness.

## Owner decision and next boundary

The owner chose **1: A** and **2: Y** on 2026-11-14: public, unprivileged telemetry first and acceptance of this discovery contract. Alternative B is not selected. The [remote decision record](https://github.com/szymoniwacz/mac-thermal-control/issues/1#issuecomment-6879220276) preserves the exact scope.

Toolchain availability and exact native calls remain implementation-planning prerequisites. Hardware compatibility and numerical overhead budgets remain unvalidated. The approval grants no privileged operation, SMC write, hardware test or workload. Later AppleSMC read-interface review, any necessary privilege, control, independent recovery and optional Ruby Mode retain their separate gates.
