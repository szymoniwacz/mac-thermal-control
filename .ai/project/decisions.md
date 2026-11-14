# Project Decisions

Confirmed by the owner's project-definition request and follow-up decisions, 2026-11-13. These are product directions, not implementation authorization. Detailed acceptance proposals and open choices live in [requirements](../docs/project-requirements.md).

| ID | Confirmed decision | Consequence |
|---|---|---|
| D-001 | Build Mac Thermal Control as an open-source macOS application for Intel Macs | Start with the owner's MacBookPro11,5 on macOS Monterey 12.7.6; expand only with evidence |
| D-002 | Smart Auto is the primary feature | Use temperatures, trends, CPU/GPU activity, and performance indicators to maximize sustained performance and minimize thermal throttling |
| D-003 | Hardware safety is essential | Verify fan limits, detect faults, reliably fall back to Apple automatic fan control, and prohibit unsafe SMC writes |
| D-004 | First implementation goal is local, read-only discovery and telemetry | Automatically gather design/validation/benchmark evidence without changing fan settings; workloads follow thermal safety checks |
| D-005 | Later scope includes benchmarking and optional Ruby Mode | Ruby Mode uses both fans at their verified supported maxima under appropriate protections |
| D-006 | Use the existing ai-project-template workflow; the original definition request was documentation only | Historical request boundary: no Issues, product code, commits, pushes, or project automation; see Execution history for later scoped work |

## Follow-up decisions

| ID | Confirmed decision | Consequence |
|---|---|---|
| D-007 | CLI first with JSON/JSONL exports; user-friendly macOS GUI in final product; no language preference | Initial direction: investigate SMC compatibility and safety before stack selection; resolved by D-017 |
| D-008 | Necessary privileged read-only operations may be explicitly approved; SMC writes need separate safety validation and authorization | No blanket approval to elevate or write; discovery remains strictly read-only |
| D-009 | Measurements stay local; no automatic uploads; owner controls sharing/deletion | Export and diagnostic design must preserve this policy; detailed minimization remains proposed |
| D-010 | Use MIT and retain existing Szymon Iwacz copyright | Existing LICENSE applies to the product; notice retained unchanged |
| D-011 | Human-reviewed PRs, macOS CI where feasible, and validation on actual MacBookPro11,5; defer signed releases | CI supplements device validation; implementation/CI configuration and release work remain future authorized tasks |

## Definition refinements

| ID | Confirmed decision | Consequence |
|---|---|---|
| D-012 | Benchmark Apple Auto, existing Macs Fan Control profile (CPU PECI, 50–80°C), and Smart Auto under equivalent workloads | Three required comparators; detailed protocol and per-fan configuration recorded before authorized runs |
| D-013 | Preserve earlier observations as historical reference data, separate measurements from conclusions, and do not treat them as controlled benchmarks | H-001 now resolved as historical transcription documented; original raw logs unavailable; no independent-validation claim |
| D-014 | First goal is an automatic local read-only diagnostic tool for capabilities, sensors, fan characteristics and performance telemetry | Explicitly report missing/unsupported information; no assumed compatibility or control writes |
| D-015 | Required final macOS GUI has a dedicated implementation phase | Roadmap phase 7 delivers GUI; optional Ruby Mode is phase 8; final product is incomplete without GUI |
| D-016 | Resolve H-001 using the owner's transcription from an earlier ChatGPT conversation; original raw logs unavailable | Preserve exact reported samples/context in the dedicated historical reference; no verified fan limits, thermal-level interpretation, throttling conclusion or controlled benchmark claim |

## Owner approvals — 2026-11-13

Recorded from the owner's explicit local Codex response in [Project #1](https://github.com/szymoniwacz/mac-thermal-control/issues/1#issuecomment-6863771976).

| ID | Confirmed decision | Consequence |
|---|---|---|
| D-017 / S-001 | Option A: Swift/Foundation with a minimal reviewed C boundary | Stack choice approved after the Monterey investigation; exact toolchain/SDK, dependencies and target compatibility still require review and validation |
| D-018 | Current project definition approved (definition: Y) | H-001 remains historical transcription with original raw logs unavailable; proposed details retain their documented review gates, including R-001 |

At the decision-recording handoff, bootstrap readiness remained unpassed. No privileged operation, hardware stress test, controlled workload or SMC write is authorized by these approvals. No GUI framework, privilege mechanism, controller algorithm or numeric hardware limit is selected. That historical session was limited to recording decisions; it did not authorize the next Agent Goal. Apply the [execution boundaries](scope.md#execution-boundaries) to future work.

## Execution history

These records describe past request boundaries, not standing permission for future runs. GitHub issues and PRs retain the execution and validation evidence.

- **2026-11-13 — definition:** D-006 recorded the documentation-only request; it excluded Issues, product implementation, commits, pushes and automation.
- **2026-11-13 — research/readiness:** the owner explicitly requested local execution of [Project #1](https://github.com/szymoniwacz/mac-thermal-control/issues/1), limited to one delegated goal. [Agent Goal #2](https://github.com/szymoniwacz/mac-thermal-control/issues/2) prepared the compatibility/safety investigation, S-001 proposal and readiness gaps in [PR #3](https://github.com/szymoniwacz/mac-thermal-control/pull/3). That request covered its Issue/commit/push/review-ready PR lifecycle and excluded product implementation, hardware operations, cloud automation and a second goal.

## S-001 resolution

[Monterey telemetry research and stack proposal](../../docs/monterey-telemetry-research.md) supplied the evidence for approved option A (D-017). S-001 is resolved; this does not establish target-device compatibility or safety. No third-party dependency, GUI framework, numeric hardware limit or recovery design has been adopted. Goal #7 delivered readiness-safe documentation in owner-merged PR #8; the subsequent readiness recheck is recorded in requirements.

## Bootstrap assessment — Goal #7

The owner's subsequent local Project #1 invocation authorizes one readiness-safe goal, with self-correcting review and no auto-merge. [Goal #7](https://github.com/szymoniwacz/mac-thermal-control/issues/7) prepares the bootstrap documentation. Human review remains required by the project and bootstrap gate; this invocation does not waive it.

The available reusable stack profiles do not match the approved Swift/C stack, so stack guidance is marked `not-applicable`. No profile or dependency is adopted. Under the greenfield bootstrap exception, actual application commands, exact toolchain/SDK and product CI are explicitly deferred to the first scaffold-producing discovery goal. See the [readiness assessment](../docs/project-requirements.md#project-readiness) for evidence and remaining gates. These are bootstrap dispositions, not new hardware or product design approvals.

## Bootstrap recheck and R-001 proposal — Goal #9

On 2026-11-14, the new local Project #1 invocation selected self-correcting review with eligible auto-merge, superseding earlier human-only merge wording for this run only. Mandatory review and hardware safety gates remain; no standing authorization or background automation is created.

PR #8 is owner-merged as `a4d3c6ff1f3c398a8bfbcc1657a734d4d4ab90bb`; its main CI run 43577417652 passed both adapter jobs. The [fresh bootstrap assessment](../docs/project-requirements.md#project-readiness) passes with the recorded greenfield command/toolchain/product-CI deferrals. This does not certify product or target-device behavior. Earlier pending-bootstrap descriptions in this file are historical handoff state.

The [R-001 specification](../../docs/discovery-specification.md) recommends a public-source first slice and a later separately reviewed AppleSMC adapter. Sequencing, schema/minimization, bounds and failure handling remain proposals awaiting owner acceptance before affected implementation. No new product design decision, dependency, source interface, privilege or hardware operation is approved by this record.
