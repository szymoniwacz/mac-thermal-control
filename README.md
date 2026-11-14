# Mac Thermal Control

An open-source macOS application planned for Intel Macs. Its primary feature, **Smart Auto**, will proactively adjust cooling using temperatures, temperature trends, CPU/GPU activity, and performance indicators to improve sustained performance and reduce thermal throttling.

Hardware safety takes precedence: verified fan limits, fault detection, reliable return to Apple's automatic fan control, and no unsafe SMC writes. Later stages include comparative benchmarking and optional **Ruby Mode**, which requests both fans' respective maximum verified supported RPM.

## Status

Early implementation; the owner approved the current definition and Swift/Foundation with a minimal reviewed C boundary (S-001: A). Bootstrap PR #8 is merged and readiness rechecked with explicit greenfield deferrals. The owner approved [R-001 A/Y](docs/discovery-specification.md). The Swift CLI currently emits explicitly synthetic fixtures only; it has no live telemetry or fan control. There is no installer, hardware validation or demonstrated performance improvement. Initial target: the owner's **MacBookPro11,5, macOS Monterey 12.7.6**.

The first implementation goal is a **local, read-only CLI for hardware discovery and passive telemetry**, exporting **JSON/JSONL**. It automatically collects hardware capabilities, available sensors, fan characteristics and performance telemetry, explicitly reporting missing or unsupported information rather than assuming compatibility. The discovery CLI must not change fan settings or generate workloads. A dedicated required roadmap phase implements the user-friendly macOS GUI. Controlled workload testing follows thermal safety checks in a later phase.

Later benchmarks must compare **Apple Auto**, the owner's **Macs Fan Control profile (CPU PECI, 50–80°C)**, and **Smart Auto** under equivalent workloads. Historical observations must be preserved as reference data, with measurements and conclusions separate; they are not controlled benchmarks. H-001 is resolved as [historical transcription documented; original raw logs unavailable](docs/historical-reference-2026-11-13.md).

## Project documentation

- [Requirements, discovery contract, and review status](.ai/docs/project-requirements.md)
- [Vision](.ai/project/vision.md), [scope](.ai/project/scope.md), and [roadmap](.ai/project/roadmap.md)
- [Monterey telemetry investigation and S-001 stack decision](docs/monterey-telemetry-research.md)
- [Confirmed decisions](.ai/project/decisions.md) and [glossary](.ai/project/glossary.md)

## Development

The owner approved the current project definition on 2026-11-13. The historical transcription is documented with its evidence limitations; it is not independently verified raw data or controlled benchmarks. The [source investigation](docs/monterey-telemetry-research.md) informed the approved Swift/Foundation stack with a minimal reviewed C boundary; see [decisions](.ai/project/decisions.md#owner-approvals--2026-11-13). The [bootstrap assessment](.ai/docs/project-requirements.md#project-readiness) records the passed bootstrap recheck and accepted R-001 decisions and remaining implementation/safety gates. Exact toolchain/SDK selection and target-device validation remain pending; see [architecture direction](.ai/docs/architecture-direction.md).

Measurements will stay local, with no automatic uploads; the owner controls sharing/deletion. Necessary privileged read-only operations require explicit approval; any SMC writes require separate safety validation and authorization and are excluded from discovery.

Use human-reviewed PRs, macOS CI where feasible, and validation on the actual MacBookPro11,5. Signed releases are deferred.

Build and exercise the synthetic-only report core with `bash scripts/test-product.sh` on an Intel Mac, then `.build/contract-tests/mac-thermal-control --demo --format jsonl`. A complete SwiftPM toolchain also supports `swift build` and `swift run ContractTests`. See [development](docs/development.md) for real commands, test coverage, local compiler/SDK limitations and remaining live-source work. No demo or test accesses hardware; default CLI invocation refuses collection. Product CI tests synthetic behavior only. No reusable stack profile matches Swift/C; stack guidance remains `not-applicable`.

This repository uses the private `ai-project-template` workflow through `.ai-template`. Agents start at [AGENTS.md](AGENTS.md), then `.ai/README.md`. Keep the project-owned `.ai/` overlay intact and reusable private workflow files out of public commits. See [workflow setup](docs/setup.md) and [automation integration documentation](docs/automation-setup.md); follow the [project execution boundaries](.ai/project/scope.md#execution-boundaries). Work requires explicit owner authorization, runs one goal at a time in local Codex, and follows the explicitly selected review/merge mode; conditional agent squash merge requires eligible Low risk, green CI and explicit auto-merge authorization. Mandatory review/safety gates remain; background automation is excluded.

## License

[MIT](LICENSE). Copyright (c) 2026 Szymon Iwacz; existing notice retained as confirmed by the owner.
