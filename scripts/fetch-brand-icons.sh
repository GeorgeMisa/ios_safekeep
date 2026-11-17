#!/usr/bin/env bash
# Downloads a pinned simple-icons release (CC0) once at dev time and bundles the curated subset.
# The app itself never touches the network.
set -euo pipefail

VERSION="16.38.0"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir "$WORK/download"
(cd "$WORK/download" && npm pack "simple-icons@${VERSION}" --silent >/dev/null)
mkdir "$WORK/unpacked"
tar -xzf "$WORK"/download/simple-icons-*.tgz -C "$WORK/unpacked"

python3 -I "$ROOT/scripts/build_brand_catalog.py" \
  "$WORK/unpacked/package" \
  "$ROOT/scripts/brands.tsv" \
  "$ROOT/SafeKeep/Resources" \
  "$ROOT/scripts/brand-logos"
