#!/usr/bin/env bash
# escape-tests.sh - Validate that room-404-not-found has been ESCAPED (fixed)
#
# Success criteria:
# - Pod is Running and Ready
# - Container is using a valid, pullable image
# - Pod hasn't restarted recently

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-room-404-not-found"
POD_NAME="escape-app"

echo "=== Testing room-404-not-found (escaped/fixed state) ==="
echo ""

# Verify pod exists
if ! kubectl get pod "$POD_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo -e "${RED}No pod named '$POD_NAME' found in namespace $NAMESPACE${NC}"
    echo "Make sure you've applied the room first: make room-apply ROOM=room-404-not-found"
    exit 1
fi

# Check pod is running
test_start "Pod is Running"
PHASE=$(get_pod_phase "$POD_NAME" "$NAMESPACE")
if [ "$PHASE" = "Running" ]; then
    test_pass "$PHASE"
else
    WAITING_REASON=$(get_waiting_reason "$POD_NAME" "$NAMESPACE")
    if [ -n "$WAITING_REASON" ]; then
        test_fail "Pod is still waiting: $WAITING_REASON"
    else
        test_fail "Pod is in '$PHASE' state, expected 'Running'"
    fi
fi

# Check pod is ready
test_start "Pod is Ready"
READY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
if [ "$READY" = "True" ]; then
    test_pass
else
    test_fail "Pod is not Ready"
fi

# Check the image was successfully pulled
test_start "Container image was pulled successfully"
IMAGE=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].image}' 2>/dev/null || echo "")
IMAGE_READY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")

if [ "$IMAGE_READY" = "true" ] && [ -n "$IMAGE" ]; then
    test_pass "Image: $IMAGE"
else
    test_fail "Container image not ready"
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
echo "You successfully fixed the image reference so Kubernetes"
echo "could pull the container image."
echo ""
