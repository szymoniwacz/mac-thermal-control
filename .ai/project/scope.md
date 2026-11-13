# Scope

## In scope now

The owner’s local request for [Project Execution #1](https://github.com/szymoniwacz/mac-thermal-control/issues/1) authorizes one delegated research/readiness goal, [#2](https://github.com/szymoniwacz/mac-thermal-control/issues/2), through a review-ready PR: investigate Monterey telemetry/SMC safety, propose S-001 and assess readiness gaps. No product implementation or hardware operation is in scope. Proposed details remain distinct from owner-confirmed requirements.

## First implementation goal — not yet authorized

A local, read-only CLI hardware discovery and telemetry tool exporting JSON/JSONL for MacBookPro11,5 on Monterey 12.7.6. Automatically collect hardware capabilities, available sensors, fan characteristics, and performance telemetry; collect passive time series; explicitly report missing, unsupported, denied, or unverified information instead of assuming compatibility. See [requirements](../docs/project-requirements.md) for proposed acceptance criteria.

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

Record meaningful changes in [decisions](decisions.md) and update requirements before proceeding. The earlier definition request did not authorize execution. The subsequent local request authorizes only the single research goal and its Issue/branch/commit/push/PR lifecycle; it does not enable background automation or a second goal.
