#!/usr/bin/env bash
# tests.sh - Validate that room-crashloop-env is in the expected failure state
# This script is used by CI to verify the room was applied correctly
set -euo pipefail

NAMESPACE="${NAMESPACE:-escape-room-crashloop-env}"
POD_NAME="escape-app"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "Testing room: room-crashloop-env"
echo "Namespace: $NAMESPACE"
echo ""

# Test 1: Pod exists
echo -n "Test 1: Pod '$POD_NAME' exists... "
if kubectl get pod "$POD_NAME" -n "$NAMESPACE" &> /dev/null; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    echo "Pod '$POD_NAME' does not exist in namespace '$NAMESPACE'"
    exit 1
fi

# Test 2: Pod is in CrashLoopBackOff or Error state (not Running successfully)
echo -n "Test 2: Pod is in failure state... "
POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
CONTAINER_STATE=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].state}' 2>/dev/null || echo "")
RESTART_COUNT=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")

# The pod should either be:
# - In CrashLoopBackOff (waiting state with reason CrashLoopBackOff)
# - Recently crashed (restartCount > 0)
# - In Error/Failed state

if echo "$CONTAINER_STATE" | grep -q "CrashLoopBackOff"; then
    echo -e "${GREEN}PASS${NC} (CrashLoopBackOff)"
elif echo "$CONTAINER_STATE" | grep -q "Error"; then
    echo -e "${GREEN}PASS${NC} (Error state)"
elif [ "$RESTART_COUNT" -gt 0 ]; then
    echo -e "${GREEN}PASS${NC} (Restart count: $RESTART_COUNT)"
elif [ "$POD_STATUS" = "Failed" ]; then
    echo -e "${GREEN}PASS${NC} (Failed status)"
else
    # If pod is Running with 0 restarts, that means it was fixed - which is wrong for the test
    if [ "$POD_STATUS" = "Running" ] && [ "$RESTART_COUNT" -eq 0 ]; then
        echo -e "${RED}FAIL${NC}"
        echo "Pod is Running successfully - this room should have a broken pod"
        exit 1
    fi
    echo -e "${GREEN}PASS${NC} (Status: $POD_STATUS)"
fi

# Test 3: Verify the error is about missing DATABASE_URL
echo -n "Test 3: Error message mentions DATABASE_URL... "
LOGS=$(kubectl logs "$POD_NAME" -n "$NAMESPACE" --previous 2>/dev/null || kubectl logs "$POD_NAME" -n "$NAMESPACE" 2>/dev/null || echo "")

if echo "$LOGS" | grep -q "DATABASE_URL"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${YELLOW}WARN${NC} (Could not verify error message - pod may not have logs yet)"
fi

echo ""
echo -e "${GREEN}All critical tests passed!${NC}"
echo "Room is in expected failure state."
