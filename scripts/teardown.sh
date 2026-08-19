#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${DOOM_NAMESPACE:-doom}"
RELEASE_NAME="${DOOM_RELEASE:-harness-doom}"
IMAGE_NAME="${DOOM_IMAGE:-harness-doom}"

echo "=== TEARING DOWN DOOM ==="

# Uninstall Helm release
echo "[1/3] Uninstalling Helm release..."
helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE" 2>/dev/null || echo "  (already removed)"

# Delete namespace
echo "[2/3] Deleting namespace '$NAMESPACE'..."
kubectl delete namespace "$NAMESPACE" --ignore-not-found

# Remove local image
echo "[3/3] Removing local image..."
docker rmi "$IMAGE_NAME:latest" 2>/dev/null || true

echo ""
echo "=== DOOM HAS BEEN VANQUISHED ==="
