#!/usr/bin/env bash
set -euo pipefail

# Build the real module, CLI and fixture cases directly with swiftc. Some Apple
# Command Line Tools installations have no SwiftPM manifest module or XCTest.
# A complete SwiftPM installation is still independently checked by product CI.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/.build/contract-tests"
mkdir -p "$BUILD"

swiftc -warnings-as-errors -swift-version 5 -target x86_64-apple-macosx12.0 \
  -emit-module -emit-library -module-name DiscoveryCore \
  -emit-module-path "$BUILD/DiscoveryCore.swiftmodule" \
  "$ROOT"/Sources/DiscoveryCore/*.swift \
  -Xlinker -install_name -Xlinker @rpath/libDiscoveryCore.dylib \
  -o "$BUILD/libDiscoveryCore.dylib"

for target in ThermalCLI DiscoveryCoreTests; do
  if [[ "$target" == ThermalCLI ]]; then
    source_directory="$ROOT/Sources/ThermalCLI"
    output_name=mac-thermal-control
  else
    source_directory="$ROOT/tests/DiscoveryCoreTests"
    output_name=ContractTests
  fi
  swiftc -warnings-as-errors -swift-version 5 -target x86_64-apple-macosx12.0 \
    -I "$BUILD" -L "$BUILD" -lDiscoveryCore \
    -Xlinker -rpath -Xlinker @executable_path \
    "$source_directory"/*.swift -o "$BUILD/$output_name"
done
"$BUILD/ContractTests"
python3 - "$BUILD/mac-thermal-control" <<'PY'
import json
import subprocess
import sys

binary = sys.argv[1]
refused = subprocess.run([binary], capture_output=True, check=False)
assert refused.returncode == 2 and refused.stdout == b''
demo = subprocess.run([binary, '--demo', '--format', 'json'], capture_output=True, check=True)
inventory = json.loads(demo.stdout)
assert inventory['schema_version'] == 1
assert inventory['configuration']['mode'] == 'synthetic_demo'
assert b'No hardware accessed' in demo.stderr
stream = subprocess.run([binary, '--demo'], capture_output=True, check=True)
records = [json.loads(line) for line in stream.stdout.splitlines()]
assert [record['type'] for record in records] == ['session_start', 'sample', 'sample', 'session_end']
assert records[-1]['complete'] is True
broken = subprocess.Popen([binary, '--demo', '--duration', '600'], stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE)
broken.stdout.close()
assert broken.wait(timeout=15) == 3
broken.stderr.close()
print('PASS executable refusal, JSON, JSONL and broken-output handling (synthetic only)')
PY
