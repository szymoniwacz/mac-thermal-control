# Monterey telemetry investigation and S-001 proposal

Prepared 2026-11-13 for [Agent Goal #2](https://github.com/szymoniwacz/mac-thermal-control/issues/2), under [Project Execution #1](https://github.com/szymoniwacz/mac-thermal-control/issues/1).

Status: **research completed; owner subsequently approved S-001: A and the current project definition on 2026-11-13**. See the [decision record](../.ai/project/decisions.md#owner-approvals--2026-11-13). Recommendation wording and readiness assessments below preserve the research-stage evidence and proposals; exact toolchain/SDK and dependencies remain subject to review and validation. Bootstrap readiness remains unpassed. The approvals authorize no privileged operations, hardware stress tests or SMC writes. The owner will resume Project Executor separately; no next Agent Goal is started in this decision-recording session. This is source research, not target-device validation. No hardware commands, telemetry capture, privileged operations, workload generation, fan changes, builds or dependency installation were performed. The initial MacBookPro11,5 / Monterey 12.7.6 configuration is owner-reported. The [historical transcription](historical-reference-2026-11-13.md) remains unchanged and is not compatibility, safety or benchmark proof.

## Findings and candidate sources

Primary sources were retrieved on 2026-11-13. Revision links freeze inspected implementation evidence; Apple documentation describes APIs, not certification of this particular Mac. Candidate access levels below are proposals to verify later, not approved operations.

| Desired observation | Evidence and candidate interface | Access / compatibility limitation |
|---|---|---|
| Model, memory, OS and CPU inventory | Apple's [XNU inventory definitions](https://github.com/apple-oss-distributions/xnu/blob/f6217f891ac0bb64f3d375211650a4c1ff8ca1ea/bsd/kern/kern_mib.c) expose read-only model/memory properties; [ProcessInfo](https://developer.apple.com/documentation/foundation/processinfo) exposes OS version | Begin unprivileged with a small field allowlist; actual Intel properties and GPU inventory still require target checks. Do not retain serials, UUIDs, host/account names or unfiltered registry dumps. Current XNU source is not a Monterey ABI guarantee. |
| CPU activity | Apple's [processor_info.h](https://github.com/apple-oss-distributions/xnu/blob/f6217f891ac0bb64f3d375211650a4c1ff8ca1ea/osfmk/mach/processor_info.h) defines CPU tick counters for processor load | Candidate unprivileged Mach reads. Compute deltas over measured intervals; handle reset/wrap/failure. Activity is not throughput, frequency or evidence of thermal throttling. |
| Thermal state | Apple's [thermal awareness guide](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/RespondToThermalStateChanges.html) documents ProcessInfo thermal state and notifications | Public API, but older/unsupported systems may always report nominal. Nominal is not proof of safe temperature or absence of throttling. No numeric temperature comes from this API. |
| Power source context | Apple's [IOPSCopyPowerSourcesInfo](https://developer.apple.com/documentation/iokit/1523839-iopscopypowersourcesinfo) provides power-source information | Candidate unprivileged IOKit reads; expose selected AC/battery fields only. Battery discharge is not CPU package power or whole-system calibrated power. |
| Fan count, identity, RPM, readable bounds; temperature keys | [SMCKit SMC.swift](https://github.com/beltex/SMCKit/blob/afb7147e32c9d37e962abab0140064cf33b9c68f/SMCKit/SMC.swift) implements Intel AppleSMC transactions, key metadata/enumeration and decoding | Reverse-engineered/private driver protocol. Opening/reading may fail or be denied. Key existence, type, size, units and physical sensor mapping require verification. Readable minimum/maximum values remain reported bounds, not independently verified safe limits. |
| Thermal performance limits | Apple's [pmset manual source](https://github.com/apple-oss-distributions/PowerManagement/blob/d415e45501842834a280930c3eed9186544a67f0/pmset/pmset.1) describes `-g therm` and `-g thermlog`, explicitly platform-dependent | A future collector could allow only these read forms after target review. `pmset` also changes settings: never expose arbitrary arguments. Current manual source does not certify Monterey output fields, meanings or availability. |
| Frequency, power, limit reasons, GPU activity | Apple identifies `powermetrics` as an analysis tool in its [energy monitoring guide](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/MonitoringEnergyUsage.html) | Exact Monterey samplers, privilege needs, formats and Intel/AMD coverage were not established here. Treat any required elevation as a separate approval gate. Do not invoke it automatically or install a helper. |

GPU inventory, integrated/discrete GPU activity attribution, CPU/GPU live frequency and package power remain **capability gaps** until target evidence establishes sources and semantics. A nameplate/base frequency is not a sampled operating frequency. Apple Silicon IOReport/HID examples are not evidence for this Intel/AMD machine. Do not add a private IOReport dependency merely to fill these gaps. Missing, denied, invalid, stale and unsupported results must remain distinct from zero.

## SMC safety boundary proposed for discovery

Apple documents the generic [IOConnectCallStructMethod transport](https://developer.apple.com/documentation/iokit/1514274-ioconnectcallstructmethod); that does not document AppleSMC command semantics or make all calls read-only. SMCKit is implementation evidence, not an Apple support contract.

The inspected SMCKit revision uses an outer driver selector and an inner command byte. It sends key reads, metadata and enumeration through the same low-level route as `writeData` and a fan setter. A transaction necessarily sends a request buffer to the driver; that is different from sending an SMC command that mutates fan/control state. Merely using an IOKit call or naming a wrapper “read” cannot enforce the boundary.

Proposed implementation safeguards, subject to later design review:

- A narrow native boundary exposing only connection lifecycle, bounded key metadata/enumeration and value reads. No exported arbitrary selector/command interface, write opcode, setter, control CLI or privileged helper.
- Review both outer selector and inner command, structure layout/alignment, lengths, returned driver status, key metadata and decoder behavior. Reject unsupported types and malformed or oversized data. Never reinterpret failure as a measurement.
- A fake transport must record every outgoing transaction and prove that only the reviewed read operations are reachable. Add malformed response, unsupported key, permission-denied and timeout/cancellation coverage before owner-run capture.
- Bound polling, enumeration, allocation, duration and retries. A blocked driver call needs an isolation/timeout design; a timer around a synchronous call alone cannot guarantee cancellation.
- Preserve stable raw key identity, units, provenance and mapping confidence. Do not assume CPU PECI equals CPU die or that known community labels apply to this Mac. Do not probe limits by writes.
- Read-only collection must not alter fan mode, targets, bounds or other control state, start workloads, change power policy, install services or automatically upload reports. The owner runs hardware-specific validation and controls sharing.

No library or architectural boundary is adopted in this goal. Later custom control requires separately verified semantics, per-fan limits, controller exclusion, independent recovery after process failure and observed restoration of Apple automatic control. A normal exit handler, successful read or claimed library compatibility cannot pass that gate.

## Candidate stacks and dependencies

The comparison is an engineering assessment inferred from the cited interfaces; no candidate was built or benchmarked here.

| Candidate | Advantages for this project | Costs and unresolved checks |
|---|---|---|
| **Swift with a small reviewed C interoperability boundary** — recommended proposal | Foundation supports structured output; direct access to native APIs; CLI logic can be reused by a later native GUI. A small C boundary makes the undocumented structure layout easier to inspect. | Unsafe native calls still need review. Use a Monterey-compatible toolchain/API subset; do not assume current Swift packages run on Monterey. Future GUI framework remains undecided. |
| Objective-C/C with Foundation | Direct IOKit/Mach interoperation and a native AppKit GUI route; fewer cross-language ABI layers | More manual lifetime/error/serialization discipline; low-level memory safety burden. Viable alternative if reducing Swift toolchain constraints is more valuable than Swift ergonomics. |
| Rust with native FFI | Strong ownership and a testable core; [Rust's macOS support document](https://doc.rust-lang.org/rustc/platform-support/apple-darwin.html) describes Intel deployment and host-tool support | Does not remove unsafe SMC ABI work. Additional FFI and GUI integration/dependency choices; pin and verify compiler, SDK and crate support before adopting. |
| Python with native bindings or a small helper | Convenient JSON/JSONL and exploratory analysis; [Python 3.13.0 installer metadata](https://www.python.org/downloads/release/python-3130/) demonstrates a historical Monterey-compatible interpreter option | Interpreter/bindings packaging and native layout/lifetime risks; GUI integration adds choices. Historical installer compatibility is not a recommendation to ship that unpatched version. No system Python availability is assumed. |

Dependency assessment:

- [SMCKit README](https://github.com/beltex/SMCKit/blob/afb7147e32c9d37e962abab0140064cf33b9c68f/README.md) describes an old Swift 4/Xcode 9 project. Its [MIT license](https://github.com/beltex/SMCKit/blob/afb7147e32c9d37e962abab0140064cf33b9c68f/LICENSE) requires notice preservation if code is reused. Do not import the whole library: it contains write capabilities, old assumptions and its CLI has separate dependencies. A minimal read-only adaptation would require a separate source/provenance/license audit and compiler validation. No code has been copied into the product.
- [smcFanControl's command source](https://github.com/hholtmann/smcFanControl/blob/e1bd672bcd2d72eddff9b6da7b9cae38e35c4206/smc-command/smc.c) carries GPL-2.0-or-later terms and includes control behavior. Use it as research evidence only here; do not copy it into this MIT product or silently adopt its distribution obligations. Any proposed reuse needs explicit license review.
- Prefer Foundation and OS frameworks initially, with no third-party CLI or telemetry package required by this proposal. This does not remove Apple's SDK/tool license requirements. Audit any eventual reused code and transitive dependencies, preserve notices, and pin approved revisions before distribution. The project's existing MIT notice stays unchanged.

## S-001 proposal at research handoff

**Recommendation A:** Swift using the Swift 5.7 language/tooling generation, Foundation, and a minimal reviewed C boundary for AppleSMC; no whole SMC library or third-party package adoption. Initially target an **x86_64 macOS 12** executable. This is a proposal, not a stack decision or compatibility claim.

Apple's [Xcode 14.2 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-14_2-release-notes) state that it runs on Monterey 12.5 or later and includes Swift 5.7 and the macOS 13.1 SDK. That makes it a candidate local build baseline for 12.7.6, subject to the owner's installed toolchain and a future build/run check. The compiler host OS, SDK version, deployment target, linked API availability and executable architecture are separate constraints. A newer SDK is not permission to use newer APIs on Monterey. Explicitly set and test the target; SwiftPM's [supported platform configuration](https://developer.apple.com/documentation/packagedescription/supportedplatform) provides a deployment declaration.

Do not read this as a requirement to install or downgrade to old development tools. An older compiler has maintenance costs. Current Swift platform policy and newer Xcode host requirements must be evaluated independently; “latest Swift” is not a pinned Monterey baseline. A modern CI host compiling an Intel artifact does not prove it launches or reads hardware on Monterey. Keep the source compatible with the approved baseline and record the exact toolchain/SDK after owner choice. GUI feasibility comes from native interoperability; detailed AppKit/SwiftUI choice and availability remain a later decision.

Alternatives for owner review:

- **B — Objective-C/C:** retain direct native APIs and avoid Swift package/toolchain constraints, accepting more low-level implementation work.
- **C — Rust:** prioritize an ownership-oriented core, accepting native FFI and later GUI integration work.
- **D — Python:** prioritize a diagnostic prototype, accepting interpreter/native binding packaging and a later GUI integration decision.
- **Other:** state a preferred approach or request further research.

The owner should choose A/B/C/D/Other separately on Project Execution #1 before implementation or stack-dependent bootstrap. Reviewing/merging this research PR alone does not approve A. No performance advantage is claimed for any language.

## Readiness gaps and next safe sequence at research handoff

| Gate | Assessment at this goal |
|---|---|
| Definition | Requirements cover the intended outcome; owner acceptance of proposed details/definition is not inferred from project execution authorization. |
| S-001 | Investigation and recommendation prepared; owner selection pending. No active stack profile or product dependencies selected. |
| Product-facing repository | README describes the product and AGENTS.md points to the private workflow. Full customization and bootstrap-marker audit still required. |
| Architecture | Existing architecture direction is still a template placeholder. After S-001, record reviewed project boundaries without copying reusable workflow. |
| Product commands | No scaffold exists. Explicitly defer real setup/run/build/test/lint/typecheck commands and product CI to the first authorized scaffold-producing goal; do not create throwaway packaging to satisfy readiness. |
| CI / review | Current CI validates adapter scripts on Linux/macOS only. Human review/merge policy is confirmed; product checks, exact baseline and branch/approval configuration remain to be reviewed during bootstrap. |
| Target evidence | No target inventory, sensor coverage, SMC access, GPU/performance coverage or read-only execution is verified by this research. Owner-run validation follows reviewed implementation. |
| Safety / readiness | Workloads, control writes, recovery and Ruby Mode gates remain closed. Project ready for first product task is **not declared**. |

After human review of this goal: obtain the S-001 decision and definition/proposed-detail decisions needed for the scoped first version; run a separately authorized readiness-safe bootstrap goal to finalize project context, approved stack guidance, deferrals and readiness record. Only after readiness passes may another authorized goal create the discovery scaffold and record actual commands/product CI. Review the read-only transaction boundary before owner-run passive capture. Review capability gaps before approving any dependent safety assessment or controlled workloads.

No next goal is selected or authorized by this document. Resume manually through local Codex; no cloud/background execution is enabled.
