#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${DOOM_NAMESPACE:-doom}"
RELEASE_NAME="${DOOM_RELEASE:-doom-gate}"
GAME_IMAGE="${DOOM_GATE_IMAGE:-harness-doom-gate}"
GATE_IMAGE="${DOOM_GATE_SERVER_IMAGE:-doom-gate-server}"
TAG="${DOOM_TAG:-latest}"

echo "=== DOOM GATE SETUP ==="
echo "  Namespace: $NAMESPACE"
echo "  Release:   $RELEASE_NAME"
echo ""

# Build images
echo "[1/4] Building DOOM gate game image..."
docker build -t "$GAME_IMAGE:$TAG" -f app/Dockerfile.gate app/

echo "[2/4] Building gate server image..."
docker build -t "$GATE_IMAGE:$TAG" -f app/doom-gate/Dockerfile app/doom-gate/

# Create namespace
echo "[3/4] Creating namespace..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Deploy via Helm
echo "[4/4] Deploying via Helm..."
helm upgrade --install "$RELEASE_NAME" helm/doom-gate \
  --namespace "$NAMESPACE" \
  --set game.image.repository="$GAME_IMAGE" \
  --set game.image.tag="$TAG" \
  --set gateServer.image.repository="$GATE_IMAGE" \
  --set gateServer.image.tag="$TAG" \
  --wait --timeout 60s

echo ""
echo "=== DOOM GATE DEPLOYED ==="
echo ""
echo "  Game:        http://localhost:30666"
echo "  Gate Server: http://localhost:30667"
echo ""
echo "  Beat E1M1 to approve the pipeline!"
echo "  Check gate status: curl http://localhost:30667/status"
echo ""
echo "  Tear down: helm uninstall $RELEASE_NAME -n $NAMESPACE"
echo ""
