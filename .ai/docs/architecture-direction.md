# Architecture Direction

## Approved direction

Mac Thermal Control starts as a local, read-only discovery and passive telemetry CLI for Intel macOS. The owner approved Swift/Foundation with a minimal reviewed C boundary (S-001 / D-017). A user-friendly macOS GUI is required later; its framework is undecided. See [requirements](project-requirements.md) and the [Monterey investigation](../../docs/monterey-telemetry-research.md).

The report core and synthetic-only Swift CLI are the first product increment; there are no third-party dependencies or live source adapters. This document records approved constraints and proposed decomposition, not a verified SMC interface or a detailed implementation design.

## Discovery structure — R-001 A/Y approved

- Keep source access behind a narrow read-only boundary. Review every native call and any dependency for hidden control operations; do not expose fan-write operations in discovery.
- Normalize available observations with source identity, units, timestamps and explicit missing/denied/unverified states. Preserve the distinction between measurements and interpretations.
- Keep collection scheduling, report serialization and CLI presentation separate from source access so failure and schema behavior can be tested with fixtures without contacting hardware.
- Bound source waits, sampling and local output. Review exact limits and minimization fields before capture; no automatic uploads.

The owner accepted the [R-001 contract](../../docs/discovery-specification.md) for public, unprivileged telemetry first (D-019). Exact native calls and later SMC interfaces remain separately reviewed. No sensor key, numeric fan limit, control selector or privileged helper is selected. Privileged reads require explicit operation approval; discovery never generates workloads or changes fan/control state.

## Deferred implementation choices

Goal #11 establishes a Swift 5.7-compatible package, real build/demo/test commands and fixture-only product CI; see [development](../../docs/development.md) for toolchain evidence and limitations. Validate deployment and API availability for Monterey separately from the build host. Neither adapter nor synthetic product CI proves target-device compatibility.

R-001 approves the staged plan, schemas, privacy minimization, cadence/storage bounds and source-failure contract; live source calls, secure persistence and scheduling are not implemented by the synthetic CLI. Later roadmap gates own workload protocols, controller ownership, independent Apple-auto recovery, Smart Auto policy, GUI design and optional Ruby Mode. No custom control is available before those gates.

## Data and recovery boundaries

Measurements remain local with owner-controlled sharing and deletion. No persistent privileged service or control recovery mechanism is introduced in discovery. Later control needs independently effective restoration of Apple automatic control, including main-process failure, before activation is allowed. See [scope](../project/scope.md) for authorization boundaries.
