# Project Vision

## One-sentence vision

Mac Thermal Control is an open-source macOS application for Intel Mac owners that aims to improve sustained performance through proactive, safety-first fan control.

## Problem

Cooling behavior, thermal throttling, and workload performance need to be measured together before a different fan policy can be designed or judged. The project must establish evidence for the actual machine instead of assuming sensor meanings, fan limits, or control behavior.

## Desired outcome

Smart Auto will use temperatures, temperature trends, CPU/GPU activity, and performance indicators to anticipate cooling demand, maximize sustained performance, and minimize thermal throttling. Hardware safety takes precedence over performance.

The final product will have a user-friendly macOS GUI. The first useful deliverable is a local, read-only CLI hardware discovery and telemetry tool exporting JSON/JSONL for the owner's MacBookPro11,5 running macOS Monterey 12.7.6. It must not change fan settings. It will automatically collect hardware capabilities, available sensors, fan characteristics and performance telemetry, reporting missing or unsupported information rather than assuming compatibility. Later equivalent-workload comparisons must include Apple Auto, the owner's existing Macs Fan Control profile (CPU PECI, 50–80°C), and Smart Auto. Earlier observations must be preserved as historical references, separate from conclusions and controlled benchmarks; H-001 now preserves the supplied transcription with original raw logs unavailable, as documented in requirements.

## Non-goals

No fan control or induced workloads in the first goal. No unsafe SMC writes, bypass of hardware protections, or performance guarantees before measurement. Apple Silicon and non-macOS platforms are outside the initial scope.
