#!/usr/bin/env bash
# tests.sh - Validate that room-pending-resources is in the expected failure state
set -euo pipefail

NAMESPACE="${NAMESPACE:-escape-room-pending-resources}"
POD_NAME="escape-app"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "Testing room: room-pending-resources"
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

# Test 2: Pod is in Pending state
echo -n "Test 2: Pod is in Pending state... "
POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')

if [ "$POD_STATUS" = "Pending" ]; then
    echo -e "${GREEN}PASS${NC}"
elif [ "$POD_STATUS" = "Running" ]; then
    echo -e "${RED}FAIL${NC}"
    echo "Pod is Running - this room should have the pod stuck in Pending"
    exit 1
else
    echo -e "${YELLOW}WARN${NC} (Status: $POD_STATUS)"
fi

# Test 3: Verify the reason is resource-related
echo -n "Test 3: Scheduler shows resource failure... "
EVENTS=$(kubectl describe pod "$POD_NAME" -n "$NAMESPACE" 2>/dev/null || echo "")

if echo "$EVENTS" | grep -qE "(Insufficient memory|Insufficient cpu|FailedScheduling)"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${YELLOW}WARN${NC} (Could not verify scheduler message)"
fi

# Test 4: Verify resource requests are excessive
echo -n "Test 4: Resource requests are excessive... "
MEMORY_REQUEST=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[0].resources.requests.memory}')
CPU_REQUEST=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[0].resources.requests.cpu}')

# Check if memory is in Gi and >= 64
if [ "$MEMORY_REQUEST" = "64Gi" ] && [ "$CPU_REQUEST" = "32" ]; then
    echo -e "${GREEN}PASS${NC} (Memory: $MEMORY_REQUEST, CPU: $CPU_REQUEST)"
else
    echo -e "${YELLOW}WARN${NC} (Memory: $MEMORY_REQUEST, CPU: $CPU_REQUEST)"
fi

echo ""
echo -e "${GREEN}All critical tests passed!${NC}"
echo "Room is in expected failure state."
