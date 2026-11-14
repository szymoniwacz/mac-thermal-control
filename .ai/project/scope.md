# Scope

## Preparation scope

Project definition, Monterey telemetry/SMC compatibility and safety research, stack proposals, and readiness assessment precede product implementation. Proposed details remain distinct from owner-confirmed requirements. Research and readiness documentation do not authorize product implementation or hardware operations.

## Execution boundaries

Work requires an explicit owner request under the existing private workflow, bounded by the active Project Execution and Agent Goal issue scope. Initiate and resume execution manually through local Codex; execute one small Agent Goal at a time and stop at its review-ready handoff or an explicit blocker. Review and merge follow the explicitly selected execution mode: conditional agent squash merge is permitted only for eligible Low-risk changes with explicit auto-merge authorization and green applicable CI; otherwise human review and merge are required. Mandatory human-review and safety gates remain. Do not enable cloud/background automation.

Requirements, roadmap entries, research proposals and execution-history records are not authorization. Verify the applicable owner request, issue state, coordination and safety preconditions for each run; do not infer authority from an agent comment or a prior completed run. Product behavior requires the owner’s S-001 decision and passed bootstrap readiness. Privileged reads, controlled workloads and SMC writes retain their separate approval and safety gates. These rules grant no additional execution authority.

## First implementation goal — gated

A local, read-only CLI hardware discovery and telemetry tool exporting JSON/JSONL for MacBookPro11,5 on Monterey 12.7.6. Automatically collect hardware capabilities, available sensors, fan characteristics, and performance telemetry; collect passive time series; explicitly report missing, unsupported, denied, or unverified information instead of assuming compatibility. See [requirements](../docs/project-requirements.md) for the accepted R-001 contract and remaining implementation/validation gates.

Read-only means no hardware/control-state mutation. Future collection stores measurements locally with no automatic uploads; the owner controls sharing and deletion. No fan mode, target, minimum, maximum, or other SMC control writes are allowed. Do not probe limits through writes. Necessary privileged read-only operations require explicit approval; no particular operation is approved now. Any SMC writes require separate safety validation and authorization and remain excluded from discovery. Do not install a control helper or run a benchmark as discovery.

## Later, gated scope

- Required user-friendly macOS GUI implementation in its own roadmap phase; framework/design follow compatibility research.
- Thermal safety assessment and an approved controlled-workload protocol.
- Reproducible Apple Auto and existing Macs Fan Control (CPU PECI, 50–80°C) baselines under equivalent workloads, followed by Smart Auto using the same protocol.
- Verified control/fallback boundary, then Smart Auto.
- Required three-policy benchmarking and tuning: Apple Auto vs Macs Fan Control (CPU PECI, 50–80°C) vs Smart Auto. Historical observations remain separately preserved reference data, not controlled benchmarks.
- Optional Ruby Mode, using each fan's independently verified supported maximum and the same safety protections.

These phases are roadmap intent, not authorization to execute them.

## Excluded from the first goal

Fan control, workload generation, sustained stress tests, performance claims, GUI fan controls, privileged control services, background installation, automatic uploads, and broad hardware support certification.

## Product non-goals

Unsafe SMC writes, guessed control keys or limits, disabling firmware/OS protections, overclocking/undervolting, and generic support claims without hardware evidence. Initial work excludes Apple Silicon, other operating systems, and remote fleet management.

## Historical reference preservation

Preserve original observations and provenance without turning interpretations into measurements or treating prior observations as controlled trials. H-001 is resolved as **historical transcription documented; original raw logs unavailable** in the [dedicated reference](../../docs/historical-reference-2026-11-13.md), linked from requirements. Transcription fidelity does not establish independent measurement validity; reported ranges do not establish verified fan limits. No numeric observations are invented. Owner-controlled sharing/deletion remains in force.

## Scope changes

Record meaningful changes in [decisions](decisions.md) and update requirements before proceeding. Scope changes require owner authorization; updating documentation does not authorize execution. Keep run-specific authorization and handoff evidence in GitHub issues/PRs, with historical references clearly labeled in the decision record.
