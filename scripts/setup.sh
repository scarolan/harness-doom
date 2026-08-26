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
  --set image.pullPolicy=Never \
  --set namespace="$NAMESPACE" \
  --wait --timeout 60s

echo ""
echo "=== DOOM IS DEPLOYED ==="
echo ""
NODE_PORT=$(kubectl get svc "$RELEASE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')

# Port-forward for reliable access (NodePort can be flaky on WSL2)
pkill -f "port-forward.*svc/${RELEASE_NAME}" 2>/dev/null || true
sleep 2
kubectl port-forward -n "$NAMESPACE" svc/"$RELEASE_NAME" "${NODE_PORT}:80" --address 0.0.0.0 </dev/null &>/dev/null &
echo "Access DOOM at: http://localhost:${NODE_PORT}"
echo ""
echo "Rip and tear, until it is done."
