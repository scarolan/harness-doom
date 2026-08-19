#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${DOOM_NAMESPACE:-doom}"
RELEASE_NAME="${DOOM_RELEASE:-harness-doom}"

echo "=== DOOM SMOKE TEST ==="

NODE_PORT=$(kubectl get svc "$RELEASE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')
URL="http://localhost:${NODE_PORT}"

echo "Testing $URL ..."

for i in $(seq 1 10); do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL/healthz" 2>/dev/null || echo "000")
    if [ "$STATUS" = "200" ]; then
        echo "Health check: PASS"
        BODY=$(curl -s "$URL")
        if echo "$BODY" | grep -qi "doom"; then
            echo "Content check: PASS (DOOM page served)"
            echo ""
            echo "Result: ALL TESTS PASSED"
            exit 0
        else
            echo "Content check: FAIL (page does not contain 'doom')"
            exit 1
        fi
    fi
    echo "  Attempt $i/10: status=$STATUS, retrying in 3s..."
    sleep 3
done

echo "Result: FAILED (service not responding after 30s)"
exit 1
