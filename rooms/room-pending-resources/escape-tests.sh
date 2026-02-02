#!/usr/bin/env bash
# escape-tests.sh - Validate that room-pending-resources has been ESCAPED (fixed)
#
# Success criteria:
# - Pod is Running and Ready (not Pending)
# - Pod was successfully scheduled to a node
# - Pod hasn't restarted recently

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-room-pending-resources"
POD_LABEL="app=escape-app"

echo "=== Testing room-pending-resources (escaped/fixed state) ==="
echo ""

# Get pod name
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$POD_NAME" ]; then
    echo -e "${RED}No pod found with label $POD_LABEL in namespace $NAMESPACE${NC}"
    echo "Make sure you've applied the room first: make room-apply ROOM=room-pending-resources"
    exit 1
fi

# Check pod is running (not pending)
test_start "Pod is Running (not Pending)"
PHASE=$(get_pod_phase "$POD_NAME" "$NAMESPACE")
if [ "$PHASE" = "Running" ]; then
    test_pass "$PHASE"
elif [ "$PHASE" = "Pending" ]; then
    test_fail "Pod is still Pending - resource requirements not satisfied"
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

# Check pod was scheduled to a node
test_start "Pod is scheduled to a node"
NODE=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.nodeName}' 2>/dev/null || echo "")
if [ -n "$NODE" ]; then
    test_pass "Scheduled on: $NODE"
else
    test_fail "Pod has no node assigned"
fi

# Check PodScheduled condition
test_start "PodScheduled condition is True"
SCHEDULED=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="PodScheduled")].status}' 2>/dev/null || echo "False")
if [ "$SCHEDULED" = "True" ]; then
    test_pass
else
    REASON=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="PodScheduled")].reason}' 2>/dev/null || echo "Unknown")
    test_fail "PodScheduled is False: $REASON"
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
echo "You successfully adjusted the resource requirements so the pod"
echo "could be scheduled on available cluster nodes."
echo ""
