# Historical reference — November 13, 2026

## Evidence status and provenance

**H-001: historical transcription documented; original raw logs unavailable.**

This document preserves the owner's transcription of previously reported measurements from an earlier ChatGPT conversation about Mac Thermal Control. The earlier conversation and original raw log files were not independently inspected; original raw logs are unavailable in this repository. The transcription was supplied by the owner in the H-001 completion request. Checking this document against that supplied text establishes transcription fidelity only, not authenticity, sensor accuracy, hardware compatibility, or reproducibility.

These are historical reference observations, not independently verified raw source data or controlled benchmarks. No new measurements or hardware commands were run to prepare this document. See [project requirements](../.ai/docs/project-requirements.md) for the product requirements and later safety/benchmark gates.

## Owner-reported machine and configuration

The following is reported historical context, not a new hardware inventory or validated control specification.

| Item | Reported value | Evidence limitation |
|---|---|---|
| Model / OS | MacBookPro11,5, macOS Monterey 12.7.6 | Owner-reported |
| CPU | Intel Core i7 2.5 GHz | Owner-reported; exact SKU not supplied |
| Memory | 16 GB RAM | Owner-reported |
| GPUs | Intel Iris Pro and AMD Radeon R9 M370X | Per-sample active GPU not specified |
| Fan software | Macs Fan Control 1.5.23 Free | Historical version, not a verified current installation |
| Both fan profiles | CPU PECI, with 50°C and 80°C temperature thresholds | Both fans reported configured this way; not hardware safety thresholds |
| Left fan range | 2160–6156 RPM | Reported range, not independently verified hardware limits |
| Right fan range | 2000–5700 RPM | Reported range, not independently verified hardware limits |

## Transcribed powermetrics measurements

Date supplied by the owner: **November 13, 2026**. Times below are preserved as reported; timezone/UTC offset was not supplied. Decimal precision is preserved. Blocks remain separate; gaps are not filled or treated as continuous capture. Exact powermetrics command, options, tool version, averaging windows and original output are unavailable.

### Samples A — temperature and thermal-level fields

Columns: time, CPU die °C, GPU die °C, reported fan RPM, CPU thermal level, GPU thermal level, IO thermal level.

The thermal-level fields are preserved as reported numeric values. Their units/scales and semantics are unverified; do not interpret them as temperatures, percentages, throttling severity, or safety thresholds.

```text
17:49:39 82.89 63.00 5542 75 39 39
17:49:44 81.27 62.12 5202 54 38 38
17:49:49 80.07 62.12 5052 46 36 36
17:49:54 78.83 63.88 4899 38 34 34
17:49:59 77.75 64.50 4680 31 31 31
17:50:04 79.66 65.25 4549 48 30 30
17:50:09 78.50 62.88 6075 51 48 48
17:50:14 77.69 62.50 5315 39 39 39
17:50:19 78.45 64.38 5653 52 49 49
17:50:24 77.14 63.62 6039 48 48 48
17:50:29 75.92 61.50 5881 46 46 46
17:50:34 80.20 63.88 5938 91 50 50
```

### Samples B — frequency, modeled power and temperature

Columns: time, average CPU frequency MHz, modeled package power W, CPU die °C, GPU die °C, reported fan RPM.

Power is reported as modeled package power, not an independently measured electrical input. Frequency is preserved as a reported average; aggregation semantics are not established here.

```text
17:55:28 2703.02 17.04 85.07 63.00 5210
17:55:33 2817.21 19.49 86.17 63.50 6114
17:55:38 2180.50 10.82 83.91 62.25 6004

18:09:20 2556.72 15.13 79.20 61.75 5611
18:09:25 2235.23 11.08 77.23 59.38 6096
18:09:30 2371.76 12.78 75.70 58.88 5956
18:09:35 2029.85 9.65 74.11 58.25 5803
18:09:40 2075.18 9.86 72.69 57.62 5647
18:09:45 2221.72 11.34 71.74 59.25 5491
```

## Additional previously reported observations

These statements were supplied alongside the transcription; corresponding raw output and exact timestamps were not supplied. They are not silently added as per-row fields in the sample blocks.

- Plimit values were 0 and PROCHOT values were 0 in these samples.
- `pmset -g therm` reportedly returned `CPU_Scheduler_Limit=100`, `CPU_Available_CPUs=8`, and `CPU_Speed_Limit=100`.
- Observed workloads included Chrome, Netflix, ChatGPT and ordinary desktop activity. Per-sample workload assignment and intensity were not supplied.
- The powermetrics `Fan` value was not identified as an individual left or right fan. No per-fan mapping or simultaneous two-fan RPM series can be recovered from these values alone.
- CPU PECI and CPU die readings must not be assumed equivalent. No mapping or offset was established.
- No controlled Apple Auto baseline was collected.

## Interpretation limits and conclusions

No derived performance statistics or comparative findings are asserted here. Measurements, reported context, and these interpretation limits remain separate.

These observations **neither prove nor disprove thermal throttling**. Plimit/PROCHOT reports, thermal-level values, temperatures and frequency changes do not establish a controlled causal conclusion in this record. Thermal-level semantics require separate verification before interpretation.

The reported fan ranges, including maxima, are not independently verified hardware limits and cannot authorize fan targets, Ruby Mode, control writes, or workload testing. Do not assign the unidentified fan samples to either fan or infer an out-of-range fault from that unknown mapping.

No controlled Apple Auto baseline was collected. No Smart Auto trial or controlled workload protocol is documented in the supplied historical record. Ambient conditions, AC/battery state, initial thermal state, background activity, repeat count and sampling details are not established. These records cannot rank cooling policies, quantify performance improvements, or replace future controlled benchmark runs. Keep them outside controlled-trial datasets.

The transcription may guide future diagnostic questions. Hardware capabilities, sensor semantics, fan limits and safe recovery still require the separate read-only discovery and safety-validation stages. Local ownership and owner-controlled sharing/deletion apply to this reference as to other project data.
