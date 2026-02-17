#!/usr/bin/env bash
# tests.sh - Validate room-pvc-pending is in expected failure state
#
# Expected state:
#   - StatefulSet exists
#   - PVC exists and is Pending
#   - Pod is Pending (waiting for PVC)
#   - StorageClass "fast-storage" does NOT exist
#   - Events show StorageClass not found
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-room-pvc-pending}"
STATEFULSET_NAME="escape-app"
POD_NAME="escape-app-0"
PVC_NAME="data-escape-app-0"
ROOM_NAME="room-pvc-pending"

echo -e "${CYAN}Testing room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: PVC Pending due to missing StorageClass${NC}"
echo ""

# ============================================================================
# Test 1: StatefulSet exists
# ============================================================================
test_start "StatefulSet '$STATEFULSET_NAME' exists"

if kubectl get statefulset "$STATEFULSET_NAME" -n "$NAMESPACE" &>/dev/null; then
    test_pass "StatefulSet found"
else
    test_fail "StatefulSet '$STATEFULSET_NAME' does not exist"
fi

# ============================================================================
# Test 2: PVC exists and is Pending
# ============================================================================
test_start "PVC '$PVC_NAME' exists and is Pending"

# Wait a moment for PVC to be created by StatefulSet
sleep 5

PVC_STATUS=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")

if [ "$PVC_STATUS" = "Pending" ]; then
    test_pass "PVC is Pending"
elif [ -z "$PVC_STATUS" ]; then
    test_fail "PVC '$PVC_NAME' does not exist"
else
    test_fail "PVC is '$PVC_STATUS' — expected 'Pending'"
fi

# ============================================================================
# Test 3: Pod is Pending (waiting for PVC)
# ============================================================================
test_start "Pod '$POD_NAME' is Pending"

POD_PHASE=$(get_pod_phase "$POD_NAME" "$NAMESPACE")

if [ "$POD_PHASE" = "Pending" ]; then
    test_pass "Pod is Pending"
elif [ -z "$POD_PHASE" ]; then
    # Pod might not exist yet if StatefulSet hasn't created it
    test_warn "Pod not created yet"
else
    dump_debug_info "$NAMESPACE"
    test_fail "Pod is '$POD_PHASE' — expected 'Pending'"
fi

# ============================================================================
# Test 4: StorageClass "fast-storage" does NOT exist
# ============================================================================
test_start "StorageClass 'fast-storage' does NOT exist"

if kubectl get storageclass fast-storage &>/dev/null; then
    test_fail "StorageClass 'fast-storage' exists — should be missing for this room"
else
    test_pass "StorageClass not found (as expected)"
fi

# ============================================================================
# Test 5: PVC references "fast-storage" StorageClass
# ============================================================================
test_start "PVC references StorageClass 'fast-storage'"

PVC_SC=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.storageClassName}' 2>/dev/null || echo "")

if [ "$PVC_SC" = "fast-storage" ]; then
    test_pass "storageClassName: fast-storage"
else
    test_fail "PVC storageClassName is '$PVC_SC' — expected 'fast-storage'"
fi

# ============================================================================
# Test 6: Events show StorageClass not found
# ============================================================================
test_start "Events show StorageClass error"

if assert_event_contains "$NAMESPACE" "fast-storage.*not found|ProvisioningFailed|unbound"; then
    test_pass "StorageClass error events found"
else
    test_warn "Could not verify StorageClass error events yet"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
