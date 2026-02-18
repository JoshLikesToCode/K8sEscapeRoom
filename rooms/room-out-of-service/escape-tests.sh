#!/usr/bin/env bash
# escape-tests.sh - Validate that room-out-of-service has been ESCAPED (fixed)
#
# Success criteria:
# - Pod is still Running
# - Service has at least 1 endpoint
# - Service is reachable (optional curl test)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-room-out-of-service"
POD_LABEL="app=escape-app"
SERVICE_NAME="escape-service"

echo "=== Testing room-out-of-service (escaped/fixed state) ==="
echo ""

# ============================================================================
# Test 1: Pod is still Running
# ============================================================================
test_start "Pod is Running"

POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$POD_NAME" ]; then
    test_fail "No pod found with label '$POD_LABEL'"
fi

PHASE=$(get_pod_phase "$POD_NAME" "$NAMESPACE")
if [ "$PHASE" = "Running" ]; then
    test_pass "$PHASE"
else
    test_fail "Pod is in '$PHASE' state, expected 'Running'"
fi

# ============================================================================
# Test 2: Service has endpoints
# ============================================================================
test_start "Service has at least 1 endpoint"

ENDPOINT_COUNT=$(kubectl get endpoints "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses}' 2>/dev/null | grep -o '"ip"' | wc -l || true)
ENDPOINT_COUNT=${ENDPOINT_COUNT:-0}

if [ "$ENDPOINT_COUNT" -gt 0 ]; then
    test_pass "$ENDPOINT_COUNT endpoint(s) found"
else
    test_fail "Service has no endpoints - selector still doesn't match pod labels"
fi

# ============================================================================
# Test 3: Service selector matches pod labels
# ============================================================================
test_start "Service selector matches pod labels"

# Get pod label
POD_APP_LABEL=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.labels.app}' 2>/dev/null || echo "")

# Get service selector
SVC_SELECTOR=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.selector.app}' 2>/dev/null || echo "")

if [ "$POD_APP_LABEL" = "$SVC_SELECTOR" ]; then
    test_pass "Pod label 'app=$POD_APP_LABEL' matches Service selector"
else
    test_fail "Pod label 'app=$POD_APP_LABEL' != Service selector 'app=$SVC_SELECTOR'"
fi

# ============================================================================
# Test 4: Service is reachable (via curl from a test pod)
# ============================================================================
test_start "Service is reachable"

# Create a quick curl test
CURL_OUTPUT=$(kubectl run test-curl-$$ --rm -i --image=curlimages/curl --restart=Never -n "$NAMESPACE" --timeout=30s -- curl -s -o /dev/null -w "%{http_code}" "http://$SERVICE_NAME" 2>/dev/null || echo "000")

if [ "$CURL_OUTPUT" = "200" ]; then
    test_pass "Got HTTP 200 from service"
else
    test_warn "Could not verify HTTP response (got $CURL_OUTPUT) - but endpoints exist"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  CONGRATULATIONS! You escaped the room!"
echo "==========================================${NC}"
echo ""
echo "You successfully fixed the Service selector mismatch."
echo "The Service can now route traffic to the pod."
echo ""
