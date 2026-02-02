#!/usr/bin/env bash
# tests.sh - Validate room-rbac-denied is in expected failure state
#
# Expected state: Pod runs but application fails due to RBAC permission denied
#
# Success criteria:
#   - Pod exists
#   - Pod has run at least once (might be in Error/CrashLoopBackOff due to exit 1)
#   - Logs contain "forbidden" or "FAILED"
#   - No Role/RoleBinding exists for pod-reader
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-room-rbac-denied}"
POD_NAME="escape-app"
ROOM_NAME="room-rbac-denied"
SERVICE_ACCOUNT="escape-sa"

echo -e "${CYAN}Testing room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: RBAC permission denied${NC}"
echo ""

# ============================================================================
# Test 1: Pod exists
# ============================================================================
test_start "Pod '$POD_NAME' exists"

if assert_pod_exists "$POD_NAME" "$NAMESPACE"; then
    test_pass
else
    test_fail "Pod '$POD_NAME' does not exist in namespace '$NAMESPACE'"
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
# Test 3: Pod uses the correct ServiceAccount
# ============================================================================
test_start "Pod uses ServiceAccount '$SERVICE_ACCOUNT'"

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

# Get logs (current or previous, since pod might have exited)
LOGS=$(get_pod_logs "$POD_NAME" "$NAMESPACE")

if echo "$LOGS" | grep -qi "forbidden\|FAILED\|cannot list\|permission denied"; then
    test_pass "Permission error found in logs"
else
    # Pod might still be running the first attempt
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

CAN_LIST=$(kubectl auth can-i list pods \
    --as="system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT}" \
    -n "$NAMESPACE" 2>/dev/null || echo "no")

if [ "$CAN_LIST" = "no" ]; then
    test_pass "ServiceAccount lacks permission (as expected)"
else
    test_fail "ServiceAccount CAN list pods - RBAC should deny this"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
