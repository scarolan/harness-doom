#!/usr/bin/env bash
set -euo pipefail

GATE_URL="${GATE_URL:-http://localhost:30667}"

echo "=== DOOM GATE TEST ==="
echo "  Gate URL: $GATE_URL"
echo ""

echo "[1/4] Checking gate server health..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$GATE_URL/healthz" 2>/dev/null || echo "000")
if [ "$STATUS" != "200" ]; then
    echo "  FAIL: Gate server not responding (status: $STATUS)"
    echo "  Is the gate deployed? Run: ./scripts/doom-gate-setup.sh"
    exit 1
fi
echo "  OK: Gate server healthy"

echo "[2/4] Checking initial state (should be incomplete)..."
RESPONSE=$(curl -s "$GATE_URL/status")
echo "  Response: $RESPONSE"
COMPLETE=$(echo "$RESPONSE" | grep -o '"complete": *true' || true)
if [ -n "$COMPLETE" ]; then
    echo "  Resetting state..."
    curl -s -X POST "$GATE_URL/reset" > /dev/null
    RESPONSE=$(curl -s "$GATE_URL/status")
fi
echo "  OK: Gate not yet approved"

echo "[3/4] Simulating E1M1 completion..."
APPROVE_RESPONSE=$(curl -s -X POST "$GATE_URL/complete" \
    -H "Content-Type: application/json" \
    -d '{"player": "TestDoomguy", "method": "test", "elapsed": 42}')
echo "  Response: $APPROVE_RESPONSE"

echo "[4/4] Verifying gate is now approved..."
RESPONSE=$(curl -s "$GATE_URL/status")
echo "  Response: $RESPONSE"
COMPLETE=$(echo "$RESPONSE" | grep -o '"complete": *true' || true)
if [ -n "$COMPLETE" ]; then
    echo ""
    echo "=== ALL TESTS PASSED ==="
    echo "  The gate would now allow the pipeline to proceed to production."
    echo ""
    echo "  Resetting for next run..."
    curl -s -X POST "$GATE_URL/reset" > /dev/null
    exit 0
else
    echo "  FAIL: Gate did not register completion"
    exit 1
fi
