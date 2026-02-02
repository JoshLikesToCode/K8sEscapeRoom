#!/usr/bin/env bash
# escape-tests.sh - Validate that room-secret-missing has been ESCAPED (fixed)
#
# Success criteria:
# - Secret 'db-credentials' exists
# - Pod is Running and Ready
# - Pod logs show "Application started successfully!"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-room-secret-missing"
POD_NAME="escape-app"
SECRET_NAME="db-credentials"

echo "=== Testing room-secret-missing (escaped/fixed state) ==="
echo ""

# ============================================================================
# Test 1: Secret exists
# ============================================================================
test_start "Secret '$SECRET_NAME' exists"

if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &>/dev/null; then
    test_pass
else
    test_fail "Secret '$SECRET_NAME' does not exist - create it to fix the room"
fi

# ============================================================================
# Test 2: Secret has required key
# ============================================================================
test_start "Secret has 'password' key"

if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.password}' &>/dev/null; then
    PASSWORD_VALUE=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.password}')
    if [ -n "$PASSWORD_VALUE" ]; then
        test_pass
    else
        test_fail "Secret 'password' key is empty"
    fi
else
    test_fail "Secret does not have 'password' key"
fi

# ============================================================================
# Test 3: Pod is Running
# ============================================================================
test_start "Pod is Running"

PHASE=$(get_pod_phase "$POD_NAME" "$NAMESPACE")
if [ "$PHASE" = "Running" ]; then
    test_pass "$PHASE"
else
    test_fail "Pod is in '$PHASE' state, expected 'Running'"
fi

# ============================================================================
# Test 4: Pod is Ready
# ============================================================================
test_start "Pod is Ready"

READY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
if [ "$READY" = "True" ]; then
    test_pass
else
    test_fail "Pod is not Ready"
fi

# ============================================================================
# Test 5: Application started successfully
# ============================================================================
test_start "Application shows 'started successfully' in logs"

LOGS=$(get_pod_logs "$POD_NAME" "$NAMESPACE")
if echo "$LOGS" | grep -q "Application started successfully"; then
    test_pass "Success message found"
else
    test_fail "Expected 'Application started successfully!' in logs"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  CONGRATULATIONS! You escaped the room!"
echo "==========================================${NC}"
echo ""
echo "You successfully identified and created the missing Secret"
echo "that was preventing the pod from starting."
echo ""
