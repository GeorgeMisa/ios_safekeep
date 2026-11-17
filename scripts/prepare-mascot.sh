#!/usr/bin/env bash
# Cuts the mascot poses out of their white backgrounds and installs them in the asset catalog.
# Usage: scripts/prepare-mascot.sh <folder-with-source-pngs>
set -euo pipefail

SOURCE="${1:?Pass the folder that holds the original mascot PNGs}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/SafeKeep/Resources/Assets.xcassets/Mascot"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

POSES=(
  "friendly_waving.png:waving"
  "standard_pose.png:standard"
  "proud_pose.png:proud"
  "curled_ball_pose.png:concerned"
  "Peekaboo Squirrel Spiral.png:curled"
  "sleepy_pose.png:sleepy"
  "celebrating_pose.png:celebrating"
  "holding_key.png:key"
  "searching_puzzled_pose.png:searching"
  "carrying_box.png:box"
)

mkdir -p "$ASSETS"
printf '{\n  "info" : { "author" : "xcode", "version" : 1 },\n  "properties" : { "provides-namespace" : true }\n}\n' > "$ASSETS/Contents.json"

for entry in "${POSES[@]}"; do
  file="${entry%%:*}"; name="${entry##*:}"
  swift "$ROOT/scripts/mascot/cutout.swift" "$SOURCE/$file" "$WORK/$name.png" >/dev/null
  set="$ASSETS/$name.imageset"
  rm -rf "$set"; mkdir -p "$set"
  swift "$ROOT/scripts/mascot/restore-marks.swift" "$SOURCE/$file" "$WORK/$name.png" "$set/$name.png"
  printf '{\n  "images" : [ { "filename" : "%s.png", "idiom" : "universal" } ],\n  "info" : { "author" : "xcode", "version" : 1 }\n}\n' "$name" > "$set/Contents.json"
  echo "Installed $name"
done
