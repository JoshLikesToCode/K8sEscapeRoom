#!/usr/bin/env bash
# tests.sh - Validate room-service-selector-mismatch is in expected failure state
#
# Expected state: Pod running but Service has 0 endpoints due to selector mismatch
#
# Success criteria:
#   - Pod exists and is Running
#   - Service exists
#   - Service has 0 endpoints (selector mismatch)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-room-service-selector-mismatch}"
POD_LABEL="app=escape-app"
ROOM_NAME="room-service-selector-mismatch"
SERVICE_NAME="escape-service"

echo -e "${CYAN}Testing room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: Pod Running but Service has 0 endpoints${NC}"
echo ""

# ============================================================================
# Test 1: Pod exists and is Running
# ============================================================================
test_start "Pod with label '$POD_LABEL' exists and is Running"

# Wait for pod to be created (deployment might still be rolling out)
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
# Test 3: Service has 0 endpoints (this is the bug)
# ============================================================================
test_start "Service has 0 endpoints (selector mismatch)"

ENDPOINTS=$(kubectl get endpoints "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")

if [ -z "$ENDPOINTS" ]; then
    test_pass "No endpoints (as expected - selector mismatch)"
else
    dump_debug_info "$NAMESPACE"
    test_fail "Service has endpoints ($ENDPOINTS) - should have none for this room"
fi

# ============================================================================
# Test 4: Verify the selector mismatch exists
# ============================================================================
test_start "Service selector does NOT match pod labels"

# Get pod label
POD_APP_LABEL=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.labels.app}' 2>/dev/null || echo "")

# Get service selector
SVC_SELECTOR=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.selector.app}' 2>/dev/null || echo "")

if [ "$POD_APP_LABEL" != "$SVC_SELECTOR" ]; then
    test_pass "Pod label 'app=$POD_APP_LABEL' != Service selector 'app=$SVC_SELECTOR'"
else
    test_fail "Labels match - they should be different for this room"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
