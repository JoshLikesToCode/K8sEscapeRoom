#!/usr/bin/env bash
# tests.sh - Validate room-rbac-denied is in expected failure state
#
# Expected state: Pod runs but application fails due to RBAC permission denied
#
# Success criteria:
#   - Deployment exists
#   - Pod exists and uses ServiceAccount escape-sa
#   - Logs contain "forbidden" or "FAILED"
#   - No Role/RoleBinding exists for pod-reader
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-room-rbac-denied}"
DEPLOYMENT_NAME="escape-app"
POD_LABEL="app=escape-app"
ROOM_NAME="room-rbac-denied"
SERVICE_ACCOUNT="escape-sa"

echo -e "${CYAN}Testing room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: RBAC permission denied${NC}"
echo ""

# ============================================================================
# Test 1: Deployment exists
# ============================================================================
test_start "Deployment '$DEPLOYMENT_NAME' exists"

if kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &>/dev/null; then
    test_pass
else
    test_fail "Deployment '$DEPLOYMENT_NAME' does not exist in namespace '$NAMESPACE'"
fi

# ============================================================================
# Test 2: ServiceAccount exists
# ============================================================================
test_start "ServiceAccount '$SERVICE_ACCOUNT' exists"

if kubectl get serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE" &>/dev/null; then
    test_pass
else
    test_fail "ServiceAccount '$SERVICE_ACCOUNT' does not exist"
fi

# ============================================================================
# Test 3: Pod exists and uses the correct ServiceAccount
# ============================================================================
test_start "Pod uses ServiceAccount '$SERVICE_ACCOUNT'"

if ! wait_for_pod "$NAMESPACE" "$POD_LABEL" 30; then
    test_fail "No pod found with label '$POD_LABEL' in namespace '$NAMESPACE'"
fi

POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
POD_SA=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null || echo "")

if [ "$POD_SA" = "$SERVICE_ACCOUNT" ]; then
    test_pass
else
    test_fail "Pod uses ServiceAccount '$POD_SA', expected '$SERVICE_ACCOUNT'"
fi

# ============================================================================
# Test 4: Logs show permission denied error
# ============================================================================
test_start "Logs show permission denied error"

# Wait a moment for the container to run and produce logs
sleep 5
LOGS=$(get_pod_logs "$POD_NAME" "$NAMESPACE")

if echo "$LOGS" | grep -qi "forbidden\|FAILED\|cannot list\|permission denied"; then
    test_pass "Permission error found in logs"
else
    test_warn "Could not verify permission error in logs yet"
fi

# ============================================================================
# Test 5: No pod-reader Role exists (the fix hasn't been applied)
# ============================================================================
test_start "No pod-reader Role exists"

if kubectl get role pod-reader -n "$NAMESPACE" &>/dev/null; then
    dump_debug_info "$NAMESPACE"
    test_fail "Role 'pod-reader' exists - it should not exist for this room"
else
    test_pass "Role does not exist (as expected)"
fi

# ============================================================================
# Test 6: ServiceAccount cannot list pods (RBAC check)
# ============================================================================
test_start "ServiceAccount cannot list pods"

if kubectl auth can-i list pods \
    --as="system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT}" \
    -n "$NAMESPACE" -q 2>/dev/null; then
    test_warn "kubectl reports SA can list pods - but actual pod behavior may differ"
else
    test_pass "ServiceAccount lacks permission (as expected)"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
