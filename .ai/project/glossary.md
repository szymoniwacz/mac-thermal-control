# Glossary

| Term | Project meaning |
|---|---|
| Smart Auto | Planned proactive fan policy using temperature, trends, CPU/GPU activity, and performance indicators to improve sustained performance safely |
| Ruby Mode | Optional later mode requesting both fans' respective maximum verified supported RPM |
| Apple Auto / Apple automatic fan control | Platform-managed fan behavior; required benchmark comparator and fallback destination for custom control |
| Macs Fan Control reference profile | Owner's existing CPU PECI, 50–80°C configuration; required benchmark comparator, not a measured outcome or verified hardware safety threshold |
| Historical observation | Previously reported reference evidence, preserved with its available context; not a controlled benchmark or conclusion |
| Historical transcription | Owner-supplied account of earlier reported measurements; H-001 is documented this way with original raw logs unavailable, without independent validation |
| Controlled comparison | Repeated runs with defined workloads, comparable conditions and one active fan controller, after the safety gate |
| Read-only diagnostic discovery | Automatic collection of hardware capabilities, available sensors, fan characteristics and performance telemetry without control changes; missing/unsupported information is explicit |
| SMC | System Management Controller; any future interaction requires verified semantics and a narrowly bounded safety design |
| Verified fan limit | A per-fan supported bound backed by trustworthy target-machine evidence and provenance, not a guessed constant or merely observed peak RPM |
| Temperature trend | Temperature change over time with explicit sampling and data-quality context |
| Thermal throttling | Performance limiting attributed to thermal constraints; lower clocks alone do not establish this cause |
| Performance indicator | A measured signal relevant to delivered performance or limiting behavior, with source and limitations recorded |
| Passive telemetry | Samples taken during existing use without generating a workload or changing the cooling policy |
| Capability gap | A required or desired observation that is unavailable, denied, unverified, or unreliable |
| Fail-safe fallback | Detect a fault, relinquish custom control, and verify Apple automatic control; inability to confirm restoration is an explicit failure |
| Thermal safety gate | Evidence review that must pass before controlled workload testing or later custom fan control |
