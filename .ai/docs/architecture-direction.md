# Architecture Direction

## Approved direction

Mac Thermal Control starts as a local, read-only discovery and passive telemetry CLI for Intel macOS. The owner approved Swift/Foundation with a minimal reviewed C boundary (S-001 / D-017). A user-friendly macOS GUI is required later; its framework is undecided. See [requirements](project-requirements.md) and the [Monterey investigation](../../docs/monterey-telemetry-research.md).

No product code or dependencies exist yet. This document records approved constraints and proposed decomposition, not a verified SMC interface or a detailed implementation design.

## Proposed discovery structure — R-001 review before implementation

- Keep source access behind a narrow read-only boundary. Review every native call and any dependency for hidden control operations; do not expose fan-write operations in discovery.
- Normalize available observations with source identity, units, timestamps and explicit missing/denied/unverified states. Preserve the distinction between measurements and interpretations.
- Keep collection scheduling, report serialization and CLI presentation separate from source access so failure and schema behavior can be tested with fixtures without contacting hardware.
- Bound source waits, sampling and local output. Review exact limits and minimization fields before capture; no automatic uploads.

These are design proposals for first-goal planning, not additional owner-approved requirements. No sensor key, numeric fan limit, control selector or privileged helper is selected. Privileged reads require explicit operation approval; discovery never generates workloads or changes fan/control state.

## Deferred implementation choices

The first scaffold-producing discovery goal owns exact Swift/toolchain/SDK selection, package layout, dependency/license review, real setup/run/test/lint/typecheck/build commands and applicable product CI. Validate deployment and API availability for Monterey separately from the build host. Current adapter CI does not prove target-device compatibility.

R-001 also owns source selection, schemas, privacy minimization, cadence/storage bounds and source-failure handling before affected implementation/capture. Later roadmap gates own workload protocols, controller ownership, independent Apple-auto recovery, Smart Auto policy, GUI design and optional Ruby Mode. No custom control is available before those gates.

## Data and recovery boundaries

Measurements remain local with owner-controlled sharing and deletion. No persistent privileged service or control recovery mechanism is introduced in discovery. Later control needs independently effective restoration of Apple automatic control, including main-process failure, before activation is allowed. See [scope](../project/scope.md) for authorization boundaries.
