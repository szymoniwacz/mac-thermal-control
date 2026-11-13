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

Bootstrap readiness remains unpassed. No privileged operation, hardware stress test, controlled workload or SMC write is authorized by these approvals. No GUI framework, privilege mechanism, controller algorithm or numeric hardware limit is selected. The owner requested decision recording only in this session and will resume Project Executor separately; do not start the next Agent Goal. Apply the [execution boundaries](scope.md#execution-boundaries) to future work.

## Execution history

These records describe past request boundaries, not standing permission for future runs. GitHub issues and PRs retain the execution and validation evidence.

- **2026-11-13 — definition:** D-006 recorded the documentation-only request; it excluded Issues, product implementation, commits, pushes and automation.
- **2026-11-13 — research/readiness:** the owner explicitly requested local execution of [Project #1](https://github.com/szymoniwacz/mac-thermal-control/issues/1), limited to one delegated goal. [Agent Goal #2](https://github.com/szymoniwacz/mac-thermal-control/issues/2) prepared the compatibility/safety investigation, S-001 proposal and readiness gaps in [PR #3](https://github.com/szymoniwacz/mac-thermal-control/pull/3). That request covered its Issue/commit/push/review-ready PR lifecycle and excluded product implementation, hardware operations, cloud automation and a second goal.

## S-001 resolution

[Monterey telemetry research and stack proposal](../../docs/monterey-telemetry-research.md) supplied the evidence for approved option A (D-017). S-001 is resolved; this does not establish target-device compatibility or safety. No third-party dependency, GUI framework, numeric hardware limit or recovery design has been adopted. Bootstrap readiness remains unpassed.
