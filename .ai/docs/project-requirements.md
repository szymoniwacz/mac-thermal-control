# Project Requirements

## Purpose

Canonical product requirements and decision queue for Mac Thermal Control. Companion context lives in [vision](../project/vision.md), [scope](../project/scope.md), [roadmap](../project/roadmap.md), and [decisions](../project/decisions.md).

Owner-confirmed requirements come from the project-definition request and the owner's follow-up decisions of 2026-11-13. R-001 A/Y now approves the staged public-source-first discovery contract (D-019). Other detailed acceptance criteria, architecture choices and policies labeled **proposed** remain recommendations awaiting confirmation; no operation-specific approval is inferred.

## Project summary

Mac Thermal Control is an open-source macOS application for Intel Macs. Smart Auto is its primary feature: proactively use temperatures, temperature trends, CPU/GPU activity, and performance indicators to maximize sustained performance and minimize thermal throttling. Hardware safety is essential: verified fan limits, fault detection, reliable fallback to Apple's automatic fan control, and no unsafe SMC writes.

Start with the owner's MacBookPro11,5 running macOS Monterey 12.7.6. These are owner-supplied facts; no hardware inventory has been run as part of this definition work. Exact components, sensor meanings, capabilities, and safe operating bounds remain unverified.

The first implementation goal is a local, read-only diagnostic CLI that automatically collects hardware capabilities, available sensors, fan characteristics, and performance telemetry for design, validation, and benchmarking. It reports missing, unsupported, denied, or unverified information rather than assuming compatibility. It must not change fan settings. Controlled workload testing follows thermal safety checks. Later stages include Smart Auto, comparative benchmarking, and optional Ruby Mode using both fans at their respective maximum verified supported RPM.

These requirements define product intent, not execution authorization. Follow the [project execution boundaries](../project/scope.md#execution-boundaries) and verify the explicit owner request and active issue scope before work. Execution evidence belongs in GitHub issues/PRs; [execution history](../project/decisions.md#execution-history) is historical context only. The current bootstrap readiness recheck is recorded below; scoped implementation readiness and operation-specific safety gates remain separate; R-001 A/Y is approved (D-019).

The first interface is a CLI exporting JSON/JSONL. The final product will have a user-friendly macOS GUI. The owner approved Swift/Foundation with a minimal reviewed C boundary (S-001; D-017) after the compatibility/safety investigation. Optional privileged read-only operations require explicit approval when necessary; any SMC writes require separate safety validation and authorization and remain excluded from discovery. Measurements stay local, with no automatic uploads and owner-controlled sharing and deletion. Use MIT with the existing Szymon Iwacz copyright, human-reviewed PRs, macOS CI where feasible, and validation on the actual MacBookPro11,5. Signed releases are deferred.

## Users

| User | Needs | Notes |
|---|---|---|
| Owner of the initial Mac | Automatically obtain trustworthy machine-specific evidence without fan changes | Initial validation environment |
| Intel Mac owners | Safe cooling behavior and credible sustained-performance comparisons | Broader support follows model-specific validation |
| Contributors and reviewers | Reproducible observations, documented limits, and safety evidence | Proposed supporting audience for the open-source project |

## Problems to solve

- Establish the actual target machine's observable thermal, fan, activity, and performance behavior before designing control.
- Separate verified evidence from guessed sensor labels, unverified limits, and unavailable performance signals.
- Anticipate cooling demand while retaining reliable platform-managed fallback.
- Make sustained-performance comparisons reproducible and prevent unsupported improvement claims.

## Goals

1. Establish a local read-only evidence foundation.
2. Put hardware safety ahead of performance optimization.
3. Develop and validate proactive Smart Auto after the safety and baseline gates.
4. Compare Apple Auto, the owner's existing Macs Fan Control profile (CPU PECI, 50–80°C), and Smart Auto under equivalent workloads. Preserve historical observations as reference data, separate from controlled benchmarks.
5. Deliver the required user-friendly macOS GUI as a dedicated roadmap phase.
6. Offer optional protected Ruby Mode after control safety is validated.

## Non-goals

No control writes, induced workload, or fan-limit probing by mutation in the first goal. No bypass of platform protections, overclocking, undervolting, or assumed safe numeric limits. Apple Silicon, non-macOS targets, and fleet management are excluded from initial scope. No promise that all requested metrics are available on Monterey or this hardware.

## Core workflows

### Workflow 1 — Read-only discovery and passive capture

Proposed first-goal workflow:

1. User explicitly starts a local collection session; tool identifies model, OS, and collection capabilities.
2. Tool inventories available hardware, fan data, sensors, and activity/performance sources using reviewed read-only operations.
3. Tool samples during ordinary existing use, without launching a workload or changing cooling behavior.
4. Tool records timestamps, provenance, units, validity, gaps, and collection errors.
5. User stops capture or a configured bound ends it; tool writes the approved local outputs and a capability/safety-evidence summary.
6. Review identifies what evidence is sufficient and what prevents the next phase. Missing evidence is not silently treated as success.

### Workflow 2 — Safety-gated baseline testing (later)

Review passive evidence and health first. Define monitoring coverage, conservative source-backed thresholds, abort conditions, workload limits, and recovery. Obtain separate authorization before generating load. Capture separate baseline runs for Apple Auto and the owner's existing Macs Fan Control profile (CPU PECI, 50–80°C) under equivalent workloads, with a single active controller per run. Add Smart Auto using the same protocol after its safety gate passes. Stop promptly on any safety breach or loss of required monitoring. Merely collecting baseline observations never authorizes discovery to change a profile or controller.

### Workflow 3 — Smart Auto and fault recovery (later)

Enable custom control only on a validated machine with verified limits, control semantics, and recovery. Continuously evaluate telemetry and fault state. On critical fault or user exit, relinquish custom control and verify restoration of Apple automatic control. Fault handling must account for loss of the main process, not rely solely on its normal exit handler.

### Workflow 4 — Ruby Mode (later, optional)

User explicitly selects Ruby Mode. Check both fans and their independent supported maxima; reject activation if evidence is missing. Request the verified maxima, monitor achieved RPM and health, and retain the same safety/fallback behavior as Smart Auto. Maximum RPM alone is not proof that a workload is thermally safe.

## Functional requirements

“Confirmed” records owner intent. “Proposed” supplies reviewable detail requiring confirmation before the relevant implementation.

| ID | Requirement | Stage | Basis |
|---|---|---|---|
| FR-001 | Automatically collect hardware capabilities, available sensors, fan characteristics, and performance telemetry in a local, read-only diagnostic CLI | First goal | Confirmed |
| FR-002 | Do not change fan settings; exclude all SMC/control writes and write-based probing from discovery | First goal | Confirmed read-only boundary |
| FR-003 | Collect passively; controlled workloads begin only after thermal safety checks | First goal / later gate | Confirmed |
| FR-004 | Inventory model/OS/build, CPU/GPU configuration, memory, fan identities/count, and available sensors without collecting unnecessary identifiers | First goal | R-001 accepted; implementation remains staged |
| FR-005 | Record each fan's observed RPM, any readable bounds/mode/target, source, units, and verification status; unavailable values stay unavailable | First goal | R-001 accepted; implementation remains staged |
| FR-006 | Capture available temperatures, temperature trends, CPU/GPU activity, frequency/power indicators, thermal/performance-limit signals, and power context | First goal | R-001 accepted; capability-dependent |
| FR-007 | Distinguish direct measurements, derived values, and inferred interpretations; do not equate a clock reduction with proven thermal throttling | First goal onward | R-001 accepted; implementation remains staged |
| FR-008 | Record wall-clock/session timing, monotonic elapsed time, actual sample intervals, source errors, and missing/stale/invalid states | First goal | R-001 accepted; implementation remains staged |
| FR-009 | Report missing or unsupported information instead of assuming compatibility | First goal | Confirmed; R-001 capability/status/provenance contract accepted; exact source semantics require review |
| FR-010 | Export JSON/JSONL for discovery and telemetry | First goal | Confirmed; R-001 schema versioning accepted, readable summary detail remains future work |
| FR-011 | Support bounded collection and clean cancellation; isolate source failure with bounded waits and visible partial results | First goal | R-001 accepted; implementation remains staged |
| FR-012 | Smart Auto uses temperatures, trends, CPU/GPU activity, and performance indicators to proactively control cooling | Later | Confirmed |
| FR-013 | Enforce verified fan limits, detect faults, and reliably fall back to Apple automatic control; prohibit unsafe SMC writes | Later control | Confirmed |
| FR-014 | Compare Apple Auto, Macs Fan Control (CPU PECI, 50–80°C), and Smart Auto under equivalent workloads | Later | Confirmed; detailed protocol proposed below |
| FR-015 | Optional Ruby Mode requests both fans' maximum verified supported RPM with safety protections | Later | Confirmed |
| FR-016 | Start with a CLI; provide a user-friendly macOS GUI in the final product | First goal / final product | Confirmed |
| FR-017 | Permit necessary privileged read-only operations only with explicit approval; require separate safety validation and authorization for any SMC writes | All stages | Confirmed; discovery never writes |
| FR-018 | Store measurements locally; no automatic uploads; owner controls sharing and deletion | First goal onward | Confirmed |
| FR-019 | Preserve historical observations as reference data, distinguish measurements from conclusions, and do not classify them as controlled benchmarks | Documentation / later analysis | Confirmed; H-001 resolved as historical transcription; raw logs unavailable |

## Data and inputs

The following is a proposed evidence checklist, not a claim that each source exists or is readable.

| Input | Source to investigate | Interpretation requirements |
|---|---|---|
| Hardware/OS inventory | Local read-only system interfaces | Record actual CPU/GPU identities; do not infer full configuration from model alone |
| Fan observations and readable limits | Reviewed read-only hardware interface | Preserve per-fan identity, units, provenance; observed peak is not a verified maximum |
| Temperature sensors | Available local sensor interface | Preserve stable IDs/raw labels; mark uncertain physical mapping and implausible values |
| CPU/GPU activity | Available OS telemetry | Include scope, sampling interval, and active GPU context when available |
| Frequency, power, thermal pressure, limit reasons | Available performance telemetry | Report source semantics and access limits; absence is not zero or “no throttling” |
| Power and session context | Local power-state telemetry and optional user notes | Distinguish AC/battery, sleep/wake, display/GPU transitions, ambient context if known |
| Temperature trends | Derived from valid timestamped temperature samples | Document window/derivation; reset across gaps or invalid samples |

Do not perform blind SMC key sweeps or undocumented command probing. Review each source's read-only semantics and access requirements before implementation. Discovery may identify gaps that require a separately reviewed collection approach.

### Historical observations — reference data only

Preserve supplied historical records and their provenance, explicitly identifying transcriptions when original raw records are unavailable; do not overwrite them with normalized values or newer runs. Keep original measurements/observations, derived calculations, and interpretations in separate fields or sections. Record original units, timestamps, collection source, machine/OS, active fan policy, workload, ambient/power conditions, and known gaps when supplied. Unknown context stays unknown. Any corrected transcription must retain a trace to the original. Local ownership, deletion, and sharing rules still apply; preservation does not override owner-directed deletion.

| Reference | What is available | Evidence class | Limits / status |
|---|---|---|---|
| H-001 — Earlier thermal observations | [Owner-supplied transcription of previously reported measurements](../../docs/historical-reference-2026-11-13.md), including 21 powermetrics samples and additional reports from November 13, 2026 | Historical transcription; not independently verified raw evidence or controlled benchmarks | Resolved: **historical transcription documented; original raw logs unavailable** |
| H-002 — Existing cooling profile | Historical context: Macs Fan Control 1.5.23 Free; both fans use CPU PECI, 50°C and 80°C thresholds; [reported fan ranges and machine details](../../docs/historical-reference-2026-11-13.md) | Owner-reported historical configuration; not independently verified | Reconfirm actual configuration before future comparison; reported maxima are not verified hardware limits; CPU PECI is not assumed equivalent to CPU die |

Historical observations may motivate hypotheses and source-discovery needs. They cannot establish causality, rank cooling policies, validate compatibility or fan limits, or stand in for the controlled comparison. H-001 is complete at the transcription level: the supplied values and context are documented, with original raw logs unavailable. Transcription checks do not independently validate the earlier measurements. Thermal-level semantics and individual-fan mapping remain unknown; the observations neither prove nor disprove thermal throttling.

## Outputs

Proposed outputs: hardware/capability inventory; timestamped time series; readable evidence summary; source/error diagnostics; collector/configuration/schema versions. JSON/JSONL exports and local-only measurement storage with owner-controlled sharing/deletion are confirmed. R-001 approves the schema, new-session-directory layout, minimization and failure contract; detailed readable-summary design and actual persistence implementation remain future work. Summaries must separate measured values, supported bounds, unverified readings, missing information, and conclusions.

No new hardware measurements, limits, or device telemetry dumps are generated by the current synthetic-only CLI increment. The supplied historical transcription is preserved separately with units, timestamps, provenance and known limitations; it is not new telemetry or independently validated evidence.

## Integrations

| Integration | Purpose | Required now? | Failure behavior |
|---|---|---|---|
| Local macOS hardware and telemetry interfaces | Discover and observe the initial Mac | Future first goal | Mark unavailable/denied/error; do not bypass access restrictions |
| SMC read interface, if reviewed and viable | Fan/sensor discovery | Candidate for first goal | No writes; report lack of safe access |
| Privileged read-only sources | Additional metrics when necessary | Optional; explicit operation approval required | Denial leaves a visible capability gap; no implicit elevation |
| Fan control and Apple-auto restoration | Smart Auto / Ruby Mode | Later only | Must be independently validated before custom control |
| Existing Macs Fan Control profile | Required later benchmark comparator: CPU PECI, 50–80°C | Later only; not a discovery dependency | Record actual version/settings; do not run competing controllers or change settings during discovery |
| Network services | None required for local discovery | No | No automatic measurement uploads; update behavior deferred to release design |

No implementation library, private API, helper architecture, or external command is selected by this definition.

## Constraints

- Start on MacBookPro11,5 and Monterey 12.7.6; compatibility must be demonstrated on that environment.
- Hardware safety overrides optimization; unverified bounds cannot authorize control.
- Discovery never writes fan state, including “restoration” writes. It observes; Apple-auto fallback is a later control responsibility.
- The current increment adds the synthetic-only report core/CLI and fixture product CI; preserve the reusable workflow and existing unrelated files. It adds no live source or hardware test.
- Any SMC writes require separate safety validation and authorization. Later control may use only verified, narrowly scoped writes under a reviewed safety design; discovery excludes all writes and the product always prohibits unsafe writes.

## Technical preferences

The CLI-first interface and final user-friendly macOS GUI are confirmed. The owner approved Swift/Foundation with a minimal reviewed C boundary (S-001; D-017). Exact Monterey-compatible toolchain/SDK and dependencies remain to be reviewed and validated during bootstrap and implementation planning. Preserve the investigation’s evidence limits and review read-only semantics, permission requirements and dependency behavior before implementation; stack approval does not authorize hardware probing, privileged operations, stress tests or SMC writes. The GUI framework and fan-control helper boundary remain later choices.

Proposed architecture direction: isolate read-only acquisition from normalization, quality checks, derived metrics, and reporting. Keep any future control capability outside the discovery executable. This is a boundary recommendation, not a selected framework or permission model.

## Active stack profile

Stack guidance is `not-applicable`: none of the available reusable profiles matches the approved Swift/Foundation stack with a minimal reviewed C boundary. Existing profiles remain examples, not active product rules. This bootstrap disposition is recorded in the readiness table below.

Actual synthetic-core build/demo/test commands, compiler/typechecking gates and toolchain limitations are recorded in [development](../../docs/development.md). Live telemetry/capture commands remain unavailable. No separate linter is adopted.

## Quality requirements

AC-01–AC-06 are accepted for staged discovery under R-001 A/Y; exact implementation calls and hardware validation remain separate gates:

- AC-01: Run the diagnostic CLI on the actual initial Mac/OS and automatically produce JSON/JSONL hardware-capability inventory, available sensor inventory, per-fan characteristics, performance telemetry, and coverage/gap information without a manual discovery-command checklist. Detailed summary/layout remain proposed.
- AC-02: Review the executable and dependencies for absence of hardware/control writes, workload generation, and hidden control helpers. Capture-only execution has no fan-setting mutation path. Static/fixture checks supplement target-machine validation; unchanged observed RPM is not proof of no writes.
- AC-03: Every requested capability/signal has valid observations with provenance/units/validity, or an explicit missing, unsupported, permission-denied, error, or unverified status and reason. Report readable fan bounds separately from verified supported limits. Never substitute zero, stale data, assumed compatibility, or guessed limits.
- AC-04: Repeated bounded sessions yield interpretable, versioned outputs; record sample timing, gaps, overhead, and environment. Session length, interval, and overhead budget are set before implementation validation.
- AC-05: Permission denial, unsupported sources, malformed values, timeout, cancellation, and sleep/wake interruption produce visible, bounded behavior and preserve valid partial evidence.
- AC-06: Review the evidence report for critical gaps; completion of discovery does not certify thermal safety or authorize fan control/workload testing.

Current fixture tests and real commands are documented in [development](../../docs/development.md). They verify the synthetic report core and CLI without live source access; actual-Mac hardware validation and the remaining full discovery contract still require separate work and authorization.

### Later safety and benchmark gates

Before controlled load: review observed sensor/fan health, current thermal state, monitoring freshness, known control ownership/conflicts, available limit indicators, and ability to abort. Define supported thresholds from trustworthy evidence, maximum duration/intensity, abort action, and cooldown/recovery. If critical safety evidence is absent, stop and resolve it. No numeric thresholds are invented here.

Before custom control: verify per-fan supported ranges and control semantics; allowlist needed operations; reject unknown keys and invalid/out-of-range values. Validate stale/missing sensors, unexpected RPM, fan faults, unsupported hardware, conflicting controllers, permissions/helper failure, process crash, sleep/wake, shutdown, and failed Apple-auto restoration. Recovery must be independently effective when the controller dies. If reliable fallback cannot be demonstrated, keep custom modes unavailable.

### Required benchmark comparison

The required comparison is **Apple Auto vs Macs Fan Control (CPU PECI, 50–80°C) vs Smart Auto**, using equivalent workloads on the same validated Mac/OS. Ruby Mode may be an additional comparison after its own safety gate; it never replaces one of these three. The owner's profile is a comparator, not an endorsement of its safety or effectiveness. The 50–80°C setting is not a hardware safety threshold.

Proposed protocol: predeclare identical workload versions, inputs, intensity, warmup/measurement duration, repeat count, metrics, safety stops, and analysis. Match initial thermal state/cooldown, AC/battery state, ambient conditions, background activity, GPU/display configuration, and telemetry overhead. Record unavoidable differences. Use balanced or randomized run order and repeated sessions to limit heat/order bias. Run only one fan controller at a time, explicitly verify control ownership and record transitions; never use discovery to configure or switch controllers. Profile activation and workload runs need separate safety checks and authorization. Record Macs Fan Control version, exact settings for each fan, actual CPU PECI source identity, and Smart Auto version/configuration before runs.

Report sustained throughput/latency, direct thermal/performance-limit evidence where available, temperatures, RPM, power and monitoring overhead, plus acoustic tradeoffs where measurable. Separate raw measurements, derived metrics, and conclusions; report variability, gaps and confounders. Historical observations are a separately labeled reference set and must not be pooled as controlled trials. No improvement target or claim is established before baseline evidence.

## Security and privacy requirements

Confirmed: local discovery; explicitly approved privileged read-only operations when necessary; no SMC writes without separate safety validation and authorization; local measurement storage with no automatic uploads; owner-controlled sharing and deletion. This approval policy does not approve any particular privileged operation now. Discovery remains strictly read-only even if later control writes are authorized.

Proposed implementation safeguards: least privilege, unprivileged baseline collection, and no persistent privileged service in discovery. Minimize data before storage: omit serial numbers, hardware UUIDs, account/host names, personal paths, process names/arguments, and unfiltered command dumps unless separately justified and approved. User owns local reports and chooses sharing. Logs must follow the same minimization policy. No credentials are needed for the product's first goal.

## Risks

| Risk | Impact | Mitigation / gate |
|---|---|---|
| Sensor labels, keys, or units misinterpreted | Incorrect conclusions or later unsafe control | Preserve raw identity/provenance; verify meaning; mark uncertainty |
| Readable fan bounds inaccurate or incomplete | Unsafe targets | Distinguish read, supported, and independently verified limits; no writes to probe |
| Missing GPU/performance/limit telemetry | Smart Auto or benchmark conclusions unsupported | Capability matrix and explicit gaps; revisit before dependent stages |
| Monitoring overhead changes behavior | Misleading measurements | Bounded sampling; measure overhead before benchmark claims |
| Privileged collection or dependency hides writes | Violates discovery safety | Explicit operation approval; review entire call/dependency boundary; no control capability |
| Main process dies while custom control remains | Loss of reliable fallback | Independent recovery and failure-injection validation before control |
| Workload causes excessive heat | Hardware risk | No induced load in discovery; gated protocol with monitored aborts |
| Shared reports expose identifiers | Privacy loss | Owner controls sharing/deletion; R-001 minimized exports; no automatic upload |
| Historical observations treated as controlled trials | Unsupported performance or safety conclusions | Separate reference records, measurements, calculations and conclusions; retain H-001 transcription provenance, unavailable-raw-log limitation, and unverified semantics |
| Competing fan controllers during comparison | Unattributable results or unsafe control | Verify one active controller, actual per-fan profile and safe transitions before each authorized run |
| Newer toolchain/CI misses Monterey behavior | False compatibility confidence | Actual target-Mac validation; CI does not certify hardware |

## Assumptions

These are unconfirmed and do not authorize implementation.

| Assumption | Why it matters | Confirm by |
|---|---|---|
| Some desired telemetry may be inaccessible | “Automatic” collection must report gaps honestly | Source investigation and discovery |
| Local reports can be minimized before persistence | Affects storage and debugging usefulness; R-001 field allowlist accepted; implementation still requires privacy review | First-goal schema/privacy review |
| Numeric performance targets should follow a measured baseline | Avoids ungrounded success thresholds | Baseline review before Smart Auto acceptance |

## Open questions

The five initial decision groups are answered; see D-007–D-011 in [decisions](../project/decisions.md). H-001 is resolved as historical transcription documented; original raw logs unavailable. The owner approved the current project definition (D-018); this does not authorize implementation or satisfy bootstrap readiness. Answers confirm the explicit choices recorded above, not every previously proposed implementation detail.

- **S-001 — Resolved:** the owner approved A, Swift/Foundation with a minimal reviewed C boundary, on 2026-11-13 ([decision record](https://github.com/szymoniwacz/mac-thermal-control/issues/1#issuecomment-6863771976); D-017). The [investigation](../../docs/monterey-telemetry-research.md) used primary sources; no hardware operation or target compatibility validation was performed. Exact toolchain/SDK and dependencies remain pending; the current bootstrap recheck is recorded below.
- **H-001 — Resolved:** historical transcription documented; original raw logs unavailable. See the [dedicated historical reference](../../docs/historical-reference-2026-11-13.md). No further source request blocks definition approval; this resolution does not upgrade the evidence to independently verified measurements.
- **B-001 — Comparator reconfirmation (later):** historical context now records Macs Fan Control 1.5.23 Free and both fans on CPU PECI at 50°C/80°C. Reconfirm the actual version, both fan settings and CPU PECI source identity before controlled comparison; historical configuration is not verification of a future run. CPU PECI and CPU die are not assumed equivalent. This does not block definition approval or first-goal discovery.
- **R-001 — Resolved for slice A:** the owner approved **1: A; 2: Y** on 2026-11-14: public, unprivileged telemetry first and the [discovery contract](../../docs/discovery-specification.md). [Remote decision record](https://github.com/szymoniwacz/mac-thermal-control/issues/1#issuecomment-6879220276); D-019. This accepts schema/minimization, bounds, failure handling and validation criteria; exact native calls still require implementation review. It authorizes no privileged operations, SMC writes, hardware tests or workloads. Goal #11 implements only the synthetic report core/CLI; live sources, persistence and scheduling remain future work.

Deferred later decisions: GUI framework/accessibility/localization, control helper and recovery architecture, thresholds and workload protocol, Smart Auto policy/noise tradeoffs, additional models, release packaging/signing/update policy. A user-friendly final GUI is required; only its design is deferred. Return triggers appear in the decision table and roadmap. These later choices do not block the first read-only goal unless their scope is introduced there.

## First useful version

A local, read-only diagnostic CLI that automatically collects hardware capabilities, available sensors, fan characteristics and performance telemetry, exports JSON/JSONL, and reports missing or unsupported information instead of assuming compatibility, with no fan setting changes and no generated workloads. S-001 is resolved and bootstrap was rechecked after merged PR #8; R-001 A/Y is approved; each implementation increment still requires scoped readiness and authorization. AC-01 through AC-06 remain the full discovery completion criteria; the synthetic-only CLI does not complete them.

## Later versions

Follow the gated [roadmap](../project/roadmap.md): safety assessment, Apple Auto / Macs Fan Control baselines, safe control foundation, Smart Auto, three-policy benchmarking/refinement, required macOS GUI implementation, and optional Ruby Mode. Broader hardware support follows separate evidence.

## Project decision status

Statuses follow the [project definition contract](../contracts/project-definition-contract.md). Confirmed policy is distinct from proposed engineering details. Deferred rows do not block the scoped first discovery goal; their reasons and return triggers are explicit. S-001 is resolved by D-017; bootstrap readiness was rechecked after merged PR #8. R-001 A/Y is approved; exact source calls and hardware validation remain separately gated. No `default-accepted` values are claimed.

| Area | Status | Value / notes | Link / location / return trigger |
|---|---|---|---|
| Product purpose | decided | Open-source proactive cooling for Intel Macs | Project summary; D-001/D-002 |
| Users | decided | Initial owner on specified Mac; later Intel Mac owners | Users; D-001 |
| Outcomes | decided | Maximize sustained performance, minimize throttling, preserve safety | Goals; D-002/D-003 |
| Success criteria | decided | Automatic local discovery and telemetry, JSON/JSONL, no fan changes; AC-01–AC-06 accepted under R-001; synthetic core is partial implementation | First useful version; quality requirements; D-004/D-007; R-001 |
| First useful version | decided | Local read-only CLI for automatic discovery and telemetry | First useful version; D-004/D-007 |
| Non-goals | decided | No discovery writes or pre-safety workloads; current CLI is synthetic-only | Non-goals; constraints; D-004/D-006/D-008 |
| Interfaces | decided | CLI first with JSON/JSONL; user-friendly macOS GUI in final product | D-007; FR-010/FR-016 |
| Inputs and outputs | decided | Automatic hardware capabilities, sensors, fan characteristics and performance telemetry; JSON/JSONL and explicit missing/unsupported statuses; historical references separate | Data and inputs; historical observations; outputs; D-004/D-007/D-009/D-013/D-014; R-001/H-001 |
| Architecture shape | decided | Local discovery CLI first; final macOS GUI; no control writes in discovery; R-001 read-only separation accepted; exact native boundary reviewed per source | Technical preferences; D-004/D-007; stack tracked separately in S-001 |
| Boundaries | decided | Local observation first; privileged reads require explicit approval; SMC writes require separate validation/authorization | Constraints; D-003/D-004/D-008 |
| Storage and data ownership | decided | Local measurements; owner controls sharing and deletion; no automatic uploads | D-009; security and privacy requirements |
| Retention and migrations | decided | Owner controls deletion; R-001 schema-version/status contract accepted; incompatible-reader handling remains unimplemented | D-009; outputs; R-001 schema review before implementation |
| Integrations and failure handling | decided | Local read-only sources; explicitly approved privileged reads when necessary; R-001 failure contract accepted; exact native source calls still require review | Integrations; D-008; AC-03/AC-05; R-001 |
| Authentication and authorization | decided | Explicit approval for necessary privileged reads; no SMC writes without separate safety validation and authorization | D-008; no operation-specific approval granted now |
| Secrets, privacy, and sensitive data | decided | Local measurement storage, no automatic upload, owner-controlled sharing/deletion; R-001 field minimization accepted; new fields require review | D-009; security and privacy; R-001 |
| Language, framework, and dependencies | decided | Swift/Foundation with a minimal reviewed C boundary; exact toolchain/SDK and dependencies require review and validation | S-001 resolved; D-017; bootstrap and implementation planning |
| Environments and deployment | decided | Owner's MacBookPro11,5 / Monterey 12.7.6 first; signed releases deferred | D-001/D-011 |
| Configuration | deferred | Exact options/cadence/duration await stack/source design; no scoped discovery blocker | Return: first-goal planning; review bounds before capture |
| Logging, monitoring, and errors | deferred | Measurement data policy confirmed; R-001 diagnostics/failure contract accepted; source-specific handling awaits live adapter design | Return: first-goal schema/privacy and error-handling review before implementation; R-001 |
| Tests, lint, typecheck, performance | decided | Human-reviewed changes, macOS CI where feasible, actual-Mac validation; equivalent Apple Auto / Macs Fan Control / Smart Auto comparisons; historical data excluded from trials | D-011/D-012/D-013; quality requirements; commands established in first scaffold goal |
| Scale, reliability, and cost | deferred | One local machine initially; numeric overhead/storage budgets need source evidence; no scoped discovery blocker | Return: first-goal planning and pre-capture bounds review |
| Supported platforms and compatibility | decided | Intel macOS; initial MacBookPro11,5 / Monterey 12.7.6 validation target | D-001/D-011; broader support requires validation |
| Accessibility and localization | deferred | User-friendly final GUI confirmed; detailed accessibility and languages await interface design; no CLI discovery blocker | Return: first GUI design; first CLI planning defines readable output |
| Compliance, backup, and recovery | deferred | Local reports regenerable; distribution/dependency review and backup details not needed for scoped discovery | Return: schema/data review before capture and license review before dependency distribution; hardware recovery validated before control |
| Branching, CI, release, and rollback | decided | Human-reviewed PRs, macOS CI where feasible, actual-Mac validation; signed releases deferred | D-011; exact CI/branch configuration during bootstrap; release/rollback design before distribution |
| License, ownership, and documentation expectations | decided | MIT; existing Szymon Iwacz copyright retained; product definition/docs required | D-010; LICENSE; D-006 |

## Project readiness

Assessed in [Goal #7](https://github.com/szymoniwacz/mac-thermal-control/issues/7), following the owner-approved definition and S-001. **Bootstrap readiness passes for planning the first product task**, rechecked on 2026-11-14 after owner merge of [PR #8](https://github.com/szymoniwacz/mac-thermal-control/pull/8) as `a4d3c6ff1f3c398a8bfbcc1657a734d4d4ab90bb`. Its review handoff and owner merge resolve the bootstrap PR gate; [main CI run 43577417652](https://github.com/szymoniwacz/mac-thermal-control/actions/runs/43577417652) passed both adapter jobs. No product or hardware compatibility is certified. R-001 A/Y is subsequently approved (D-019); scoped readiness and operation-specific safety gates still apply. Goal #11 implements a synthetic report core/CLI, not live capture. No hardware operation is authorized by this assessment.

| Check | Result | Evidence / remaining gate |
|---|---|---|
| Definition coverage complete | Pass | Every decision area above has an explicit status; D-018 records owner approval |
| No `blocking-question` remains | Pass for bootstrap | S-001 resolved by D-017; R-001 A/Y approved by D-019; exact native calls and device testing still gated |
| All `deferred` items have reason and return trigger | Pass | Decision table and open questions identify phase/first-goal return points |
| Template customization complete | Pass after owner merge | Product context and project-owned architecture direction filled; reusable workflow and adapters preserved |
| Stack profile selected or marked N/A | `not-applicable` | Available profiles cover Python, Ruby/Rails and TypeScript; none fits Swift/Foundation with C. Unselected reusable examples remain private and unchanged. See [architecture direction](architecture-direction.md) |
| Real project commands recorded | Recorded for synthetic core | [Development](../../docs/development.md) records SwiftPM/direct build, demo and contract-test commands, typechecking/lint applicability, compiler/SDK evidence and fixture-only product CI. Local SwiftPM manifest module is missing; direct Swift 5.7 build validates source and CI checks SwiftPM independently. Live-source commands remain unavailable |
| Root README describes the product | Pass | Product purpose, initial target, status, limitations and development pointers |
| `AGENTS.md` describes repository role | Pass | Product repository identity added; canonical workflow pointers preserved |
| Bootstrap markers removed | Pass for project-owned files | No unresolved bootstrap placeholder in tracked product documentation; private reusable examples/checklists are not product state |
| License and ownership decided | Pass | MIT; existing Szymon Iwacz copyright retained (D-010) |
| CI, branch rules, and approvals decided | Documented | GitHub PRs to main, signed commits and no direct main push; current explicit mode permits conditional Low-risk auto-merge, with mandatory review/safety gates retained. Existing adapter jobs plus Intel macOS fixture product CI. No background executor activation |
| Project ready for first product task | **Pass with explicit greenfield deferrals** | PR #8 merged; current main adapter CI passed. R-001 A/Y approved; scoped implementation readiness still precedes affected product changes; target-device compatibility and later safety gates remain unproven |

Additional bootstrap evidence: the template gitlink, setup scripts, materialized `.ai/README.md`, executor helper and thin adapters are present; no workflow update is needed. No `default-accepted` choice is claimed. Local owner-controlled reports, no automatic uploads, explicit privilege approval and the prohibition on discovery control writes remain confirmed. Initial deployment targets the owner's Mac/OS; signed distribution is deferred. Bootstrap creates no data migration or service deployment; rollback is a reviewed forward revert PR. Goal #7's PR carries local validation and green remote CI evidence and has been merged by the owner. The bootstrap check itself granted no R-001 or hardware approval; subsequent D-019 accepts R-001 A/Y while retaining all operation-specific safety gates.

### Existing repository validation

These commands validate workflow adapters only; they do not build an application, read sensors, certify hardware safety or validate Monterey runtime compatibility:

```sh
bash -n scripts/*.sh tests/test-adapter.sh
bash tests/test-adapter.sh
bash scripts/check-workflow-leak.sh
git diff --check
```

`.github/workflows/ci.yml` runs adapter checks on `ubuntu-latest` and `macos-latest` for PRs and main pushes. There is no `validate-workflow-contracts.yml` to switch to project mode. Keep both existing checks; do not treat them as product tests. Exact branch-protection configuration is not certified by this assessment; the required human review/merge policy applies regardless of GitHub enforcement.

### First product goal obligations

Bootstrap PR #8 is merged; R-001 A/Y is now approved by D-019. Goal #11 records the decisions and implements the reusable report core/synthetic CLI, real commands and fixture product CI. See [development](../../docs/development.md) for implemented scope, local SwiftPM toolchain limitations and remaining work. Live public adapters, native-call review/isolation, secure session persistence, scheduling/deadlines and device validation remain future increments. No hardware command/test, privilege, workload or SMC write is authorized by this goal. Each next increment requires scoped implementation readiness and current evidence.

## Definition review status

**Approved by the owner on 2026-11-13 (D-018).** The GUI, three-policy benchmark comparison, and diagnostic-tool scope are explicit. H-001 is resolved as **historical transcription documented; original raw logs unavailable**. The dedicated reference preserves the supplied samples, reported context and limitations without claiming independent validation or controlled benchmarks. All contract decision areas have explicit statuses; remaining engineering proposals and phase gates are visible. Definition review readiness does not certify hardware behavior or pass the separate implementation-readiness gate.

Goal #7 delivered [bootstrap customization and readiness](../onboarding/bootstrap-checklist.md) in merged PR #8; the current readiness recheck is recorded above. R-001 A/Y is approved; exact source calls and hardware validation remain separately gated. Each execution requires an explicit owner request within the [project execution boundaries](../project/scope.md#execution-boundaries); definition approval, research completion and PR merge do not substitute for implementation readiness or operation-specific safety approvals.

## Historical definition validation and review handoff

Reviewed all nine product definition/reference documents (README, six project-context files, these requirements, and the dedicated historical reference) against the owner's refinements and the definition contract. Reviewed existing setup, architecture, repository specification, and automation-loader documentation as workflow integration material; these do not select a product architecture or authorize automation. Reusable workflow and adapters were preserved.

Validation: decision-area/status coverage, required readiness rows, decision/requirement IDs, deferred-item metadata, local links, whitespace, and consistency of the GUI phase, required comparator set, discovery boundaries and historical-data status were checked. `git diff --check` and `bash scripts/check-workflow-leak.sh` passed. Self-review used the workflow review checklist; no independent agent review was requested.

Application tests, hardware/SMC validation, controlled workloads, and CI execution are not applicable to this documentation-only change and were not run. No application scaffold or product test commands exist yet; adapter test results would not establish product correctness or thermal safety. No Issues/PRs, commits, pushes, or automation were created or launched.

H-001 validation: all 21 timestamped sample rows were checked against the owner-supplied transcription, including column order and decimal precision. Reported machine/profile/ranges, Plimit/PROCHOT, pmset fields, workload context and uncertainty were preserved. This checks transcription fidelity only, not the original measurements.

Historical review focus: definition approval with H-001 classified as a transcription with unavailable raw logs, required GUI phase, three-policy comparison, and proposed acceptance/protocol details without treating them as measured results. Definition approval and S-001 were subsequently resolved by D-018/D-017; B-001 and detailed GUI/control/workload choices retain their documented phase gates.

## Historical research/readiness handoff — Goal #2

[Monterey telemetry investigation and S-001 proposal](../../docs/monterey-telemetry-research.md) records primary-source evidence, read-only boundary risks, candidate stacks and remaining readiness gaps. At the research handoff, S-001 was pending. The owner subsequently approved Swift/Foundation with a minimal reviewed C boundary (D-017) and the current definition (D-018). Target-device coverage and safety are unverified. Product commands and product CI are explicitly deferred to the first authorized scaffold-producing goal; adapter CI is not product validation. No bootstrap/readiness pass is claimed. The approval authorizes no privileged operations, hardware stress tests or SMC writes. The owner will resume separately; no next Agent Goal starts in this decision-recording session.
