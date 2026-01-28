#!/usr/bin/env bash
# tests.sh - Validate that room-imagepullbackoff is in the expected failure state
set -euo pipefail

NAMESPACE="${NAMESPACE:-escape-room-imagepullbackoff}"
POD_NAME="escape-app"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "Testing room: room-imagepullbackoff"
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

# Test 2: Pod is in ImagePullBackOff or ErrImagePull state
echo -n "Test 2: Pod is in image pull failure state... "
POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
CONTAINER_STATE=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].state}' 2>/dev/null || echo "")
WAITING_REASON=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || echo "")

if [ "$WAITING_REASON" = "ImagePullBackOff" ] || [ "$WAITING_REASON" = "ErrImagePull" ]; then
    echo -e "${GREEN}PASS${NC} ($WAITING_REASON)"
elif echo "$CONTAINER_STATE" | grep -qE "(ImagePullBackOff|ErrImagePull)"; then
    echo -e "${GREEN}PASS${NC} (Image pull error)"
else
    # If pod is Running, that means it was fixed - which is wrong for the test
    if [ "$POD_STATUS" = "Running" ]; then
        echo -e "${RED}FAIL${NC}"
        echo "Pod is Running successfully - this room should have an image pull error"
        exit 1
    fi
    echo -e "${YELLOW}WARN${NC} (Status: $POD_STATUS, may still be attempting pull)"
fi

# Test 3: Verify the image tag is the broken one
echo -n "Test 3: Image tag is 'latset' (typo)... "
IMAGE=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[0].image}')

if [ "$IMAGE" = "nginx:latset" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${YELLOW}WARN${NC} (Image: $IMAGE)"
fi

echo ""
echo -e "${GREEN}All critical tests passed!${NC}"
echo "Room is in expected failure state."
