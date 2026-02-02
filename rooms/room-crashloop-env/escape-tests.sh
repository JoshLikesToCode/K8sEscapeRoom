#!/usr/bin/env bash
# escape-tests.sh - Validate that room-crashloop-env has been ESCAPED (fixed)
#
# Success criteria:
# - Pod is Running and Ready
# - Pod shows "Application started successfully" in logs
# - Pod hasn't restarted recently

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-room-crashloop-env"
POD_LABEL="app=escape-app"

echo "=== Testing room-crashloop-env (escaped/fixed state) ==="
echo ""

# Get pod name
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$POD_NAME" ]; then
    echo -e "${RED}No pod found with label $POD_LABEL in namespace $NAMESPACE${NC}"
    echo "Make sure you've applied the room first: make room-apply ROOM=room-crashloop-env"
    exit 1
fi

# Check pod is running
test_start "Pod is Running"
PHASE=$(get_pod_phase "$POD_NAME" "$NAMESPACE")
if [ "$PHASE" = "Running" ]; then
    test_pass "$PHASE"
else
    test_fail "Pod is in '$PHASE' state, expected 'Running'"
fi

# Check pod is ready
test_start "Pod is Ready"
READY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
if [ "$READY" = "True" ]; then
    test_pass
else
    test_fail "Pod is not Ready"
fi

# Check logs show success
test_start "Application started successfully (check logs)"
LOGS=$(get_pod_logs "$POD_NAME" "$NAMESPACE")
if echo "$LOGS" | grep -q "Application started successfully"; then
    test_pass "Success message found"
else
    test_fail "Expected 'Application started successfully' in logs"
fi

# Check no recent restarts (stability check)
test_start "Pod is stable (checking for restarts)"
RESTARTS_BEFORE=$(get_restart_count "$POD_NAME" "$NAMESPACE")
sleep 5
RESTARTS_AFTER=$(get_restart_count "$POD_NAME" "$NAMESPACE")

if [ "$RESTARTS_BEFORE" = "$RESTARTS_AFTER" ]; then
    test_pass "No restarts during observation (count: $RESTARTS_AFTER)"
else
    test_fail "Pod restarted during observation ($RESTARTS_BEFORE -> $RESTARTS_AFTER)"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  CONGRATULATIONS! You escaped the room!"
echo "==========================================${NC}"
echo ""
echo "You successfully identified and fixed the missing DATABASE_URL"
echo "environment variable that was causing the CrashLoopBackOff."
echo ""
