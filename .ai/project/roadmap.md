# Roadmap

Phases describe intended sequencing, not executable authorization. Product readiness has not been declared. [Goal #2](https://github.com/szymoniwacz/mac-thermal-control/issues/2) delivered the [Monterey investigation](../../docs/monterey-telemetry-research.md). The owner approved S-001: A (Swift/Foundation with a minimal reviewed C boundary) and the current definition; see [decisions](decisions.md#owner-approvals--2026-11-13). [Goal #7](https://github.com/szymoniwacz/mac-thermal-control/issues/7) prepares readiness-safe bootstrap documentation, awaiting human review/merge. A subsequent authorized local run must reverify readiness before the first product task.

| Phase | Deliverable | Exit gate |
|---|---|---|
| 0 — Definition (current) | Project context and requirements incorporating confirmed owner decisions; owner-approved; S-001: A approved; H-001 historical transcription documented, original raw logs unavailable | Definition and stack approvals recorded; bootstrap documentation prepared in Goal #7; human bootstrap review/merge and readiness recheck pending, retaining all safety and validation gates |
| 1 — Read-only discovery | Local read-only diagnostic CLI: automatic hardware capabilities, sensors, per-fan characteristics and performance telemetry; JSON/JSONL and explicit missing/unsupported information | Demonstrate no control writes; verify provenance, timestamps, units, missing-data handling, and repeatable collection; review actual coverage |
| 2 — Safety assessment and workload protocol | Assess fan/sensor health and monitoring coverage; document thresholds, abort rules, and recovery | Owner approves a bounded protocol only after thermal safety checks; unknown critical safety evidence prevents workload testing |
| 3 — Baseline measurements | Separate Apple Auto and Macs Fan Control (CPU PECI, 50–80°C) runs under equivalent workloads | Safety-gated authorized workloads/profile transitions; single controller per run; exact per-fan profile/settings, confounders and uncertainty recorded |
| 4 — Safe control foundation | Verified per-fan limits and supported control semantics; fault detection; Apple-auto restoration | Separate safety validation and authorization for SMC writes; validate transitions, independent failure recovery, and critical fault scenarios on the target machine before enabling custom modes |
| 5 — Smart Auto | Proactive policy driven by temperature, trends, CPU/GPU activity, and performance signals | Safety checks pass; compare against baseline using predeclared metrics; no performance claim without evidence |
| 6 — Benchmarking and refinement | Required Apple Auto vs Macs Fan Control (CPU PECI, 50–80°C) vs Smart Auto comparison and tuning under equivalent workloads | Same workload protocol and comparable conditions; historical references excluded from controlled trials; report sustained throughput, throttling indicators, temperatures, RPM, overhead, and uncertainty; record acoustic/power tradeoffs where measurable |
| 7 — Required macOS GUI | Implement the user-friendly macOS GUI for telemetry, mode selection and safety/fault visibility | Validate on the initial Mac/OS; proposed usability/accessibility checks, explicit activation, visible fallback/errors, and no bypass of validated control protections; required before final product completion |
| 8 — Optional Ruby Mode | Both fans request their own maximum verified supported RPM | Explicit activation, same safety protections and verified fallback; target attainment checked; no guessed common maximum |

## Deferred until the relevant gate

Phase 7 delivers the required user-friendly macOS GUI; framework and detailed interaction/accessibility design remain later decisions. This requirement cannot be deferred out of final product completion. Broader Intel model/OS coverage, release packaging and signing, persistent helpers, localization, and advanced optimization remain deferred. Model-specific safety evidence cannot be inferred from success on the initial Mac.

Human-reviewed PRs, macOS CI where feasible, and validation on the actual MacBookPro11,5 apply to future implementation. Signed releases remain deferred.

If discovery cannot provide critical telemetry, report the gap and revisit scope or sensing options. Do not silently cross into writes, privilege escalation, or workload testing to fill it.
