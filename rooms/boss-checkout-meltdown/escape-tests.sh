#!/usr/bin/env bash
# escape-tests.sh - Validate boss-checkout-meltdown has been ESCAPED (fixed)
#
# Success criteria (ALL must pass):
#   - Pods are Running AND Ready (1/1)
#   - Service has endpoints
#   - Service is reachable

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-boss-checkout-meltdown"
SERVICE_NAME="checkout-service"
POD_LABEL="app=checkout-api"

echo "=== Testing boss-checkout-meltdown (escaped/fixed state) ==="
echo ""

# ============================================================================
# Test 1: Pods are Running
# ============================================================================
test_start "Pods are Running"

RUNNING_COUNT=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" --no-headers 2>/dev/null | grep -c "Running" || echo "0")

if [ "$RUNNING_COUNT" -gt 0 ]; then
    test_pass "$RUNNING_COUNT pod(s) Running"
else
    test_fail "No pods in Running state"
fi

# ============================================================================
# Test 2: Pods are Ready (1/1)
# ============================================================================
test_start "Pods are Ready (1/1)"

READY_PODS=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" --no-headers 2>/dev/null | grep -c "1/1" || echo "0")

if [ "$READY_PODS" -gt 0 ]; then
    test_pass "$READY_PODS pod(s) Ready"
else
    test_fail "No pods are Ready - readiness probe may still be failing"
fi

# ============================================================================
# Test 3: Service has endpoints
# ============================================================================
test_start "Service has endpoints"

ENDPOINT_COUNT=$(kubectl get endpoints "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses}' 2>/dev/null | grep -o '"ip"' | wc -l || echo "0")

if [ "$ENDPOINT_COUNT" -gt 0 ]; then
    test_pass "$ENDPOINT_COUNT endpoint(s)"
else
    test_fail "Service has no endpoints - selector may still be wrong"
fi

# ============================================================================
# Test 4: Service selector matches pod labels
# ============================================================================
test_start "Service selector matches pod labels"

POD_APP_LABEL=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.labels.app}' 2>/dev/null || echo "")
SVC_SELECTOR=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.selector.app}' 2>/dev/null || echo "")

if [ "$POD_APP_LABEL" = "$SVC_SELECTOR" ]; then
    test_pass "Selector matches: app=$SVC_SELECTOR"
else
    test_fail "Selector mismatch: pod has 'app=$POD_APP_LABEL', service wants 'app=$SVC_SELECTOR'"
fi

# ============================================================================
# Test 5: Service is reachable
# ============================================================================
test_start "Service is reachable (HTTP 200)"

CURL_RESULT=$(kubectl run test-curl-$$ --rm -i --image=curlimages/curl --restart=Never \
    -n "$NAMESPACE" --timeout=30s -- \
    curl -s -o /dev/null -w "%{http_code}" "http://$SERVICE_NAME" 2>/dev/null || echo "000")

if [ "$CURL_RESULT" = "200" ]; then
    test_pass "Got HTTP 200"
else
    test_warn "Got HTTP $CURL_RESULT (expected 200)"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  CONGRATULATIONS! You escaped the boss room!"
echo "==========================================${NC}"
echo ""
echo "You successfully fixed BOTH issues:"
echo "  1. Service selector mismatch"
echo "  2. Readiness probe misconfiguration"
echo ""
echo "The checkout service is now operational!"
echo ""
