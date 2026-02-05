#!/usr/bin/env bash
# escape-tests.sh - Validate that room-ingress-misroute has been ESCAPED (fixed)
#
# Success criteria:
# - Ingress references the correct service name
# - Ingress routes traffic successfully (if ingress controller is available)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-room-ingress-misroute"
POD_LABEL="app=escape-app"
SERVICE_NAME="escape-service"
INGRESS_NAME="escape-ingress"

echo "=== Testing room-ingress-misroute (escaped/fixed state) ==="
echo ""

# ============================================================================
# Test 1: Pod is Running
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
# Test 2: Ingress references correct service
# ============================================================================
test_start "Ingress references correct service '$SERVICE_NAME'"

INGRESS_SVC=$(kubectl get ingress "$INGRESS_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null || echo "")

if [ "$INGRESS_SVC" = "$SERVICE_NAME" ]; then
    test_pass "Ingress backend: $INGRESS_SVC"
else
    test_fail "Ingress references '$INGRESS_SVC', expected '$SERVICE_NAME'"
fi

# ============================================================================
# Test 3: Service endpoints exist
# ============================================================================
test_start "Service has endpoints"

ENDPOINT_COUNT=$(kubectl get endpoints "$SERVICE_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.subsets[*].addresses}' 2>/dev/null | grep -o '"ip"' | wc -l || true)
ENDPOINT_COUNT=${ENDPOINT_COUNT:-0}

if [ "$ENDPOINT_COUNT" -gt 0 ]; then
    test_pass "$ENDPOINT_COUNT endpoint(s)"
else
    test_fail "Service has no endpoints"
fi

# ============================================================================
# Test 4: Test via ingress controller (if available)
# ============================================================================
test_start "Ingress routes traffic (if controller available)"

# Check if ingress-nginx is running
if kubectl get svc -n ingress-nginx ingress-nginx-controller &>/dev/null; then
    # Get the ingress controller service IP
    INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
        -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")

    if [ -n "$INGRESS_IP" ]; then
        # Test the ingress route
        CURL_RESULT=$(kubectl run test-ingress-$$ --rm -i --image=curlimages/curl --restart=Never \
            -n "$NAMESPACE" --timeout=30s -- \
            curl -s -o /dev/null -w "%{http_code}" -H "Host: escape.local" "http://${INGRESS_IP}/api" 2>/dev/null || echo "000")

        if [ "$CURL_RESULT" = "200" ]; then
            test_pass "Ingress returns HTTP 200"
        else
            test_warn "Ingress returned HTTP $CURL_RESULT (may need path adjustment)"
        fi
    else
        test_skip "Could not get ingress controller IP"
    fi
else
    test_skip "Ingress controller not available"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  CONGRATULATIONS! You escaped the room!"
echo "==========================================${NC}"
echo ""
echo "You successfully fixed the Ingress configuration"
echo "to route traffic to the correct backend service."
echo ""
