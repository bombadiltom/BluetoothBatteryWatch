#!/usr/bin/env bash
# Renders the Mac App Store screenshots into AppStore/screenshots/ (2880×1800, no alpha).
# It compiles the app's real MenuContentView with a stand-in BatteryMonitor holding fixed data
# (scripts/screenshots/). Edit scenes in scripts/screenshots/main.swift and run this again.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/build/make-screenshots"
mkdir -p "$ROOT/build"
swiftc -O -swift-version 5 -o "$BIN" \
  "$ROOT/BluetoothBatteryWatch/MenuContentView.swift" \
  "$ROOT/BluetoothBatteryWatch/BatterySymbol.swift" \
  "$ROOT/BluetoothBatteryWatch/BatteryReader.swift" \
  "$ROOT"/scripts/screenshots/*.swift
"$BIN" "$ROOT"
