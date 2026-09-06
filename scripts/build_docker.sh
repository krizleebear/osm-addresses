#!/usr/bin/env bash
# scripts/build_docker.sh — Standardized Multi-Arch Container Image Builder
#
# Builds and pushes krizleebear/osm2parquet for both linux/amd64 and linux/arm64
# with --provenance=false to guarantee Docker Schema 2 compatibility across
# Azure DevOps, GHCR, and mirror.gcr.io.
#
# Usage:
#   ./scripts/build_docker.sh [version] [--no-push]
#
# Examples:
#   ./scripts/build_docker.sh v1.0.9
#   ./scripts/build_docker.sh v1.0.9 --no-push

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

VERSION="${1:-}"
NO_PUSH="false"

for arg in "$@"; do
  if [ "$arg" = "--no-push" ]; then
    NO_PUSH="true"
  elif [ -z "$VERSION" ] || [ "$VERSION" = "$arg" ]; then
    VERSION="$arg"
  fi
done

if [ -z "$VERSION" ] || [ "$VERSION" = "--no-push" ]; then
  # Auto-detect current version from azure-pipelines.yml
  VERSION=$(grep -oE 'osm2parquet:v[0-9]+\.[0-9]+\.[0-9]+' "${ROOT_DIR}/azure-pipelines.yml" | head -n 1 | cut -d: -f2 || true)
  if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> [--no-push]"
    echo "Example: $0 v1.0.9"
    exit 1
  fi
  echo "[INFO] Auto-detected version from azure-pipelines.yml: ${VERSION}"
fi

PLATFORMS="linux/amd64,linux/arm64"
DOCKER_DIR="${ROOT_DIR}/docker/osm2parquet"

IMAGE_DH="krizleebear/osm2parquet:${VERSION}"
IMAGE_GHCR="ghcr.io/krizleebear/osm2parquet:${VERSION}"

echo "================================================================="
echo " Building osm2parquet container image"
echo " Version:   ${VERSION}"
echo " Platforms: ${PLATFORMS}"
echo " Targets:   ${IMAGE_DH}"
echo "            ${IMAGE_GHCR}"
echo " Provenance: false (Docker Schema 2 safe)"
echo " Push:      $([ "$NO_PUSH" = "true" ] && echo "NO (local build only)" || echo "YES")"
echo "================================================================="

BUILD_ARGS=(
  --platform "${PLATFORMS}"
  --provenance=false
  -t "${IMAGE_DH}"
  -t "${IMAGE_GHCR}"
)

if [ "$NO_PUSH" = "true" ]; then
  # When not pushing, buildx cannot load multi-arch into local daemon directly;
  # build current host arch or test-compile both platforms.
  echo "[INFO] Building without push (validating multi-platform build)..."
  docker buildx build "${BUILD_ARGS[@]}" "${DOCKER_DIR}"
  echo "[OK] Multi-arch build succeeded (unpushed)."
else
  echo "[INFO] Building and pushing multi-platform images..."
  docker buildx build "${BUILD_ARGS[@]}" --push "${DOCKER_DIR}"
  echo "[OK] Successfully pushed ${IMAGE_DH} and ${IMAGE_GHCR} (${PLATFORMS})."
fi
