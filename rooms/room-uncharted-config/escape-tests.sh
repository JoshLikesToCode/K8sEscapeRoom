#!/usr/bin/env bash
# escape-tests.sh - Validate that room-uncharted-config has been ESCAPED (fixed)
#
# Success criteria:
# - ConfigMap 'app-config' exists
# - Pod is Running and Ready
# - Pod logs show "Application configured successfully!"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-room-uncharted-config"
POD_NAME="escape-app"
CONFIGMAP_NAME="app-config"

echo "=== Testing room-uncharted-config (escaped/fixed state) ==="
echo ""

# ============================================================================
# Test 1: ConfigMap exists
# ============================================================================
test_start "ConfigMap '$CONFIGMAP_NAME' exists"

if kubectl get configmap "$CONFIGMAP_NAME" -n "$NAMESPACE" &>/dev/null; then
    test_pass
else
    test_fail "ConfigMap '$CONFIGMAP_NAME' does not exist - create it to fix the room"
fi

# ============================================================================
# Test 2: Pod is Running
# ============================================================================
test_start "Pod is Running"

PHASE=$(get_pod_phase "$POD_NAME" "$NAMESPACE")
if [ "$PHASE" = "Running" ]; then
    test_pass "$PHASE"
else
    test_fail "Pod is in '$PHASE' state, expected 'Running'"
fi

# ============================================================================
# Test 3: Pod is Ready
# ============================================================================
test_start "Pod is Ready"

READY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
if [ "$READY" = "True" ]; then
    test_pass
else
    test_fail "Pod is not Ready"
fi

# ============================================================================
# Test 4: Application configured successfully
# ============================================================================
test_start "Application shows 'configured successfully' in logs"

LOGS=$(get_pod_logs "$POD_NAME" "$NAMESPACE")
if echo "$LOGS" | grep -q "Application configured successfully"; then
    test_pass "Success message found"
else
    test_fail "Expected 'Application configured successfully!' in logs"
fi

# ============================================================================
# Test 5: Environment variables are set
# ============================================================================
test_start "Environment variables loaded from ConfigMap"

if echo "$LOGS" | grep -q "APP_NAME:"; then
    test_pass "APP_NAME is set"
else
    test_warn "Could not verify APP_NAME in logs"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  CONGRATULATIONS! You escaped the room!"
echo "==========================================${NC}"
echo ""
echo "You successfully identified and created the missing ConfigMap"
echo "that was preventing the pod from starting."
echo ""
