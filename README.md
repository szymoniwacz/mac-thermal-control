# Mac Thermal Control

An open-source macOS application planned for Intel Macs. Its primary feature, **Smart Auto**, will proactively adjust cooling using temperatures, temperature trends, CPU/GPU activity, and performance indicators to improve sustained performance and reduce thermal throttling.

Hardware safety takes precedence: verified fan limits, fault detection, reliable return to Apple's automatic fan control, and no unsafe SMC writes. Later stages include comparative benchmarking and optional **Ruby Mode**, which requests both fans' respective maximum verified supported RPM.

## Status

Research/readiness preparation; stack selection and bootstrap are pending. There is no application, installer, hardware validation, or demonstrated performance improvement yet. Initial target: the owner's **MacBookPro11,5, macOS Monterey 12.7.6**.

The first implementation goal is a **local, read-only CLI for hardware discovery and passive telemetry**, exporting **JSON/JSONL**. It automatically collects hardware capabilities, available sensors, fan characteristics and performance telemetry, explicitly reporting missing or unsupported information rather than assuming compatibility. The discovery CLI must not change fan settings or generate workloads. A dedicated required roadmap phase implements the user-friendly macOS GUI. Controlled workload testing follows thermal safety checks in a later phase.

Later benchmarks must compare **Apple Auto**, the owner's **Macs Fan Control profile (CPU PECI, 50–80°C)**, and **Smart Auto** under equivalent workloads. Historical observations must be preserved as reference data, with measurements and conclusions separate; they are not controlled benchmarks. H-001 is resolved as [historical transcription documented; original raw logs unavailable](docs/historical-reference-2026-11-13.md).

## Project documentation

- [Requirements, proposed acceptance criteria, and review status](.ai/docs/project-requirements.md)
- [Vision](.ai/project/vision.md), [scope](.ai/project/scope.md), and [roadmap](.ai/project/roadmap.md)
- [Monterey telemetry investigation and pending S-001 stack proposal](docs/monterey-telemetry-research.md)
- [Confirmed decisions](.ai/project/decisions.md) and [glossary](.ai/project/glossary.md)

## Development

The project definition is ready for owner approval. The historical transcription is documented with its evidence limitations; it is not independently verified raw data or controlled benchmarks. The [source investigation and stack proposal](docs/monterey-telemetry-research.md) are prepared for owner review. Implementation readiness still requires the owner’s stack decision and bootstrap checks. No language has been selected.

Measurements will stay local, with no automatic uploads; the owner controls sharing/deletion. Necessary privileged read-only operations require explicit approval; any SMC writes require separate safety validation and authorization and are excluded from discovery.

Use human-reviewed PRs, macOS CI where feasible, and validation on the actual MacBookPro11,5. Signed releases are deferred.

Application setup, build, run, test, and configuration commands do not exist yet. Establish them with the first authorized implementation after stack selection and project readiness. Do not use template test results as evidence of hardware safety.

This repository uses the private `ai-project-template` workflow through `.ai-template`. Agents start at [AGENTS.md](AGENTS.md), then `.ai/README.md`. Keep the project-owned `.ai/` overlay intact and reusable private workflow files out of public commits. See [workflow setup](docs/setup.md) and [automation integration documentation](docs/automation-setup.md); the current local request authorizes one research goal through a human-review PR and does not authorize background automation.

## License

[MIT](LICENSE). Copyright (c) 2026 Szymon Iwacz; existing notice retained as confirmed by the owner.
