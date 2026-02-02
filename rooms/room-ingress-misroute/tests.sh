#!/usr/bin/env bash
# tests.sh - Validate room-ingress-misroute is in expected failure state
#
# Expected state: Ingress references wrong service name
#
# Success criteria:
#   - Pod exists and is Running
#   - Service exists
#   - Ingress exists
#   - Ingress references a non-existent service (the bug)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-room-ingress-misroute}"
POD_LABEL="app=escape-app"
ROOM_NAME="room-ingress-misroute"
SERVICE_NAME="escape-service"
INGRESS_NAME="escape-ingress"
WRONG_SERVICE="escape-svc"

echo -e "${CYAN}Testing room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: Ingress references wrong service name${NC}"
echo ""

# ============================================================================
# Test 1: Pod exists and is Running
# ============================================================================
test_start "Pod with label '$POD_LABEL' exists and is Running"

if ! wait_for_pod "$NAMESPACE" "$POD_LABEL" 30; then
    test_fail "No pod found with label '$POD_LABEL' in namespace '$NAMESPACE'"
fi

POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
pod_phase=$(get_pod_phase "$POD_NAME" "$NAMESPACE")

if [ "$pod_phase" = "Running" ]; then
    test_pass "Pod is Running"
else
    test_fail "Pod is in '$pod_phase' state, expected 'Running'"
fi

# ============================================================================
# Test 2: Service exists
# ============================================================================
test_start "Service '$SERVICE_NAME' exists"

if kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" &>/dev/null; then
    test_pass
else
    test_fail "Service '$SERVICE_NAME' does not exist"
fi

# ============================================================================
# Test 3: Ingress exists
# ============================================================================
test_start "Ingress '$INGRESS_NAME' exists"

if kubectl get ingress "$INGRESS_NAME" -n "$NAMESPACE" &>/dev/null; then
    test_pass
else
    test_fail "Ingress '$INGRESS_NAME' does not exist"
fi

# ============================================================================
# Test 4: Ingress references wrong service (the bug)
# ============================================================================
test_start "Ingress references non-existent service '$WRONG_SERVICE'"

INGRESS_SVC=$(kubectl get ingress "$INGRESS_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null || echo "")

if [ "$INGRESS_SVC" = "$WRONG_SERVICE" ]; then
    test_pass "Ingress references '$WRONG_SERVICE' (expected bug)"
elif [ "$INGRESS_SVC" = "$SERVICE_NAME" ]; then
    dump_debug_info "$NAMESPACE"
    test_fail "Ingress references correct service '$SERVICE_NAME' - should have typo for this room"
else
    test_warn "Ingress references '$INGRESS_SVC' - unexpected value"
fi

# ============================================================================
# Test 5: The wrong service does NOT exist
# ============================================================================
test_start "Service '$WRONG_SERVICE' does NOT exist"

if kubectl get svc "$WRONG_SERVICE" -n "$NAMESPACE" &>/dev/null; then
    test_fail "Service '$WRONG_SERVICE' exists - it should NOT exist for this room"
else
    test_pass "Service '$WRONG_SERVICE' does not exist (as expected)"
fi

# ============================================================================
# Test 6: Service is reachable internally (proving service works)
# ============================================================================
test_start "Service is reachable internally"

# Try to curl the service from within the cluster
CURL_RESULT=$(kubectl run test-curl-$$ --rm -i --image=curlimages/curl --restart=Never \
    -n "$NAMESPACE" --timeout=30s -- \
    curl -s -o /dev/null -w "%{http_code}" "http://$SERVICE_NAME" 2>/dev/null || echo "000")

if [ "$CURL_RESULT" = "200" ]; then
    test_pass "Internal service returns HTTP 200"
else
    test_warn "Could not verify internal connectivity (got $CURL_RESULT)"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
