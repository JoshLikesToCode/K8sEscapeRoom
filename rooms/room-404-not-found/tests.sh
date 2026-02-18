#!/usr/bin/env bash
# tests.sh - Validate room-404-not-found is in expected failure state
#
# Expected state: Pod in ImagePullBackOff due to typo in image tag (nginx:latset)
#
# Success criteria:
#   - Pod exists
#   - Container is in ImagePullBackOff or ErrImagePull state
#   - Image tag is the broken one (nginx:latset)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-room-404-not-found}"
POD_NAME="escape-app"
ROOM_NAME="room-404-not-found"
EXPECTED_IMAGE="nginx:latset"

echo -e "${CYAN}Testing room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: ImagePullBackOff (image tag typo)${NC}"
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
# Test 2: Container is in ImagePullBackOff or ErrImagePull state
# ============================================================================
test_start "Container is in ImagePullBackOff or ErrImagePull"

waiting_reason=$(get_waiting_reason "$POD_NAME" "$NAMESPACE")
pod_phase=$(get_pod_phase "$POD_NAME" "$NAMESPACE")

# ImagePullBackOff can appear as:
# 1. waiting.reason = "ImagePullBackOff" (in backoff period)
# 2. waiting.reason = "ErrImagePull" (actively failing)

if [ "$waiting_reason" = "ImagePullBackOff" ]; then
    test_pass "waiting.reason=ImagePullBackOff"
elif [ "$waiting_reason" = "ErrImagePull" ]; then
    test_pass "waiting.reason=ErrImagePull"
else
    # If pod is Running, it was fixed - that's a failure
    if [ "$pod_phase" = "Running" ]; then
        dump_debug_info "$NAMESPACE"
        test_fail "Pod is Running - expected ImagePullBackOff"
    fi
    # Might still be attempting first pull
    if [ "$pod_phase" = "Pending" ] && [ -z "$waiting_reason" ]; then
        test_warn "Pod is Pending, image pull may not have failed yet"
    else
        test_warn "Unexpected state: phase=$pod_phase, waiting=$waiting_reason"
    fi
fi

# ============================================================================
# Test 3: Events show image pull failure
# ============================================================================
test_start "Events show image pull failure"

if assert_event_contains "$NAMESPACE" "(Failed.*pull|ErrImagePull|ImagePullBackOff|manifest.*not found)"; then
    test_pass
else
    test_warn "Could not find image pull failure in events"
fi

# ============================================================================
# Test 4: Image tag is the broken one
# ============================================================================
test_start "Image is '$EXPECTED_IMAGE' (typo)"

actual_image=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].image}' 2>/dev/null || echo "")

if [ "$actual_image" = "$EXPECTED_IMAGE" ]; then
    test_pass
else
    if [ -n "$actual_image" ]; then
        dump_debug_info "$NAMESPACE"
        test_fail "Image is '$actual_image' - expected '$EXPECTED_IMAGE'"
    else
        test_warn "Could not determine image"
    fi
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
