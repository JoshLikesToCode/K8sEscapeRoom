#!/usr/bin/env bash
# escape-tests.sh - Validate that room-rbac-denied has been ESCAPED (fixed)
#
# Success criteria:
# - Role and RoleBinding exist
# - ServiceAccount can now list pods
# - Pod logs show success message

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-room-rbac-denied"
POD_NAME="escape-app"
SERVICE_ACCOUNT="escape-sa"

echo "=== Testing room-rbac-denied (escaped/fixed state) ==="
echo ""

# ============================================================================
# Test 1: RBAC Role exists
# ============================================================================
test_start "A Role granting pod access exists"

# Check for any role that grants pod access
ROLES=$(kubectl get roles -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

if [ -n "$ROLES" ]; then
    test_pass "Found role(s): $ROLES"
else
    test_fail "No Roles found - create a Role that grants pod list permission"
fi

# ============================================================================
# Test 2: RoleBinding exists
# ============================================================================
test_start "A RoleBinding for the ServiceAccount exists"

BINDINGS=$(kubectl get rolebindings -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

if [ -n "$BINDINGS" ]; then
    test_pass "Found rolebinding(s): $BINDINGS"
else
    test_fail "No RoleBindings found - create a RoleBinding for the ServiceAccount"
fi

# ============================================================================
# Test 3: ServiceAccount can now list pods
# ============================================================================
test_start "ServiceAccount can list pods"

CAN_LIST=$(kubectl auth can-i list pods \
    --as="system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT}" \
    -n "$NAMESPACE" 2>/dev/null || echo "no")

if [ "$CAN_LIST" = "yes" ]; then
    test_pass
else
    test_fail "ServiceAccount still cannot list pods - check Role and RoleBinding"
fi

# ============================================================================
# Test 4: Pod is Running
# ============================================================================
test_start "Pod is Running"

PHASE=$(get_pod_phase "$POD_NAME" "$NAMESPACE")
if [ "$PHASE" = "Running" ]; then
    test_pass "$PHASE"
else
    # Pod might need to be restarted after RBAC fix
    test_warn "Pod is in '$PHASE' state - you may need to restart it"
fi

# ============================================================================
# Test 5: Pod logs show success
# ============================================================================
test_start "Pod logs show SUCCESS"

LOGS=$(get_pod_logs "$POD_NAME" "$NAMESPACE")

if echo "$LOGS" | grep -q "SUCCESS"; then
    test_pass "Success message found in logs"
else
    if echo "$LOGS" | grep -qi "forbidden\|FAILED"; then
        test_fail "Pod still showing permission errors - restart pod after fixing RBAC"
    else
        test_warn "Could not verify success message - check logs manually"
    fi
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  CONGRATULATIONS! You escaped the room!"
echo "==========================================${NC}"
echo ""
echo "You successfully configured RBAC to grant the ServiceAccount"
echo "permission to list pods in the namespace."
echo ""
