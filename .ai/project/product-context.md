# Product Context

## Product

- Name: Mac Thermal Control.
- Purpose: safer, proactive cooling for sustained performance on Intel Macs.
- Initial user: the project owner, using MacBookPro11,5 on macOS Monterey 12.7.6; later users are Intel Mac owners.
- Primary feature: Smart Auto; later optional Ruby Mode requests both fans' maximum verified supported RPM.
- Current state: project definition only; no product implementation or hardware validation has been performed in this work. Earlier owner observations are preserved in a [historical transcription](../../docs/historical-reference-2026-11-13.md); original raw logs are unavailable (H-001 resolved).

## Repository

This is the product repository, bootstrapped from the public adapter for the private `ai-project-template` workflow. `.ai/` remains the workflow source of truth; project context is a project-owned overlay. Do not publish reusable private workflow material.

The primary requirements and decision queue live in [project requirements](../docs/project-requirements.md). [Scope](scope.md) sets authorization boundaries; [roadmap](roadmap.md) sets phase gates.

## Technical context

The initial model and OS are owner-supplied facts, not locally verified inventory. The historical reference reports an Intel Core i7 2.5 GHz, 16 GB RAM, Intel Iris Pro and AMD Radeon R9 M370X. This is owner-reported context, not independently verified inventory. Sensors, fan identities and verified limits, telemetry permissions, and available performance signals still require discovery. No numeric fan or temperature limits are assumed.

The first goal is a local read-only diagnostic CLI automatically collecting capabilities, sensors, fan characteristics and performance telemetry, exporting JSON/JSONL and explicitly reporting missing/unsupported information; the final product requires a user-friendly macOS GUI. Investigate SMC compatibility and safety before proposing the stack; the owner has no language preference. Necessary privileged read-only operations require explicit approval, and SMC writes require separate safety validation and authorization. Measurements stay local, without automatic uploads; the owner controls sharing/deletion. MIT and the existing Szymon Iwacz copyright are confirmed. Use human-reviewed PRs, macOS CI where feasible, and validation on the actual Mac; signed releases are deferred. No active stack profile or application build/run/test commands exist yet. Existing adapter commands validate workflow infrastructure only.

Required future benchmark comparators: Apple Auto, the owner's existing Macs Fan Control profile (CPU PECI, 50–80°C), and Smart Auto under equivalent workloads. Profile settings are owner-reported configuration, not thermal safety limits or controlled measurements. Historical references and conclusions remain separate; see requirements for H-001 and the evidence policy. The final GUI has its own required roadmap phase.

## Execution and readiness

Follow the [execution boundaries](scope.md#execution-boundaries); product context and roadmap intent do not authorize work. Resolve each run’s authority from the explicit owner request and active issue scope. GitHub issues/PRs retain execution evidence; [decisions](decisions.md#execution-history) preserves historical context. The definition is ready for owner approval; H-001 is resolved as historical transcription documented, original raw logs unavailable. Review the [compatibility investigation and unadopted stack proposal](../../docs/monterey-telemetry-research.md), obtain the owner’s S-001 selection, and complete bootstrap readiness before separately authorized product implementation.
