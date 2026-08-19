#!/usr/bin/env bash
set -euo pipefail

# Setup script for harness-doom
# Prerequisites: kubectl, helm, docker (or nerdctl)

NAMESPACE="${DOOM_NAMESPACE:-doom}"
RELEASE_NAME="${DOOM_RELEASE:-harness-doom}"
IMAGE_NAME="${DOOM_IMAGE:-harness-doom}"
IMAGE_TAG="${DOOM_TAG:-latest}"

echo "=== HARNESS DOOM SETUP ==="
echo "Namespace:  $NAMESPACE"
echo "Release:    $RELEASE_NAME"
echo "Image:      $IMAGE_NAME:$IMAGE_TAG"
echo ""

# Build the container image
echo "[1/3] Building DOOM container image..."
docker build -t "$IMAGE_NAME:$IMAGE_TAG" app/

# Create namespace if needed
echo "[2/3] Creating namespace '$NAMESPACE'..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Deploy with Helm
echo "[3/3] Deploying DOOM via Helm..."
helm upgrade --install "$RELEASE_NAME" helm/harness-doom \
  --namespace "$NAMESPACE" \
  --set image.repository="$IMAGE_NAME" \
  --set image.tag="$IMAGE_TAG" \
  --set namespace="$NAMESPACE" \
  --wait --timeout 60s

echo ""
echo "=== DOOM IS DEPLOYED ==="
echo ""
NODE_PORT=$(kubectl get svc "$RELEASE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')
echo "Access DOOM at: http://localhost:${NODE_PORT}"
echo ""
echo "Rip and tear, until it is done."
