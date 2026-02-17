#!/usr/bin/env bash
# escape-tests.sh - Validate room-pvc-pending has been ESCAPED (fixed)
#
# Success criteria (ALL must pass):
#   - Pod is Running and Ready (1/1)
#   - PVC is Bound
#   - StorageClass "fast-storage" exists

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-room-pvc-pending"
POD_NAME="escape-app-0"
PVC_NAME="data-escape-app-0"

echo "=== Testing room-pvc-pending (escaped/fixed state) ==="
echo ""

# ============================================================================
# Test 1: Pod is Running
# ============================================================================
test_start "Pod is Running"

PHASE=$(get_pod_phase "$POD_NAME" "$NAMESPACE")

if [ "$PHASE" = "Running" ]; then
    test_pass "$PHASE"
else
    test_fail "Pod is in '$PHASE' state, expected 'Running'"
fi

# ============================================================================
# Test 2: Pod is Ready (1/1)
# ============================================================================
test_start "Pod is Ready (1/1)"

READY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")

if [ "$READY" = "True" ]; then
    test_pass
else
    test_fail "Pod is not Ready"
fi

# ============================================================================
# Test 3: PVC is Bound
# ============================================================================
test_start "PVC is Bound"

PVC_STATUS=$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.status.phase}' 2>/dev/null || echo "")

if [ "$PVC_STATUS" = "Bound" ]; then
    test_pass "PVC is Bound"
else
    test_fail "PVC is '$PVC_STATUS' — expected 'Bound'"
fi

# ============================================================================
# Test 4: StorageClass "fast-storage" exists
# ============================================================================
test_start "StorageClass 'fast-storage' exists"

if kubectl get storageclass fast-storage &>/dev/null; then
    test_pass "StorageClass found"
else
    test_fail "StorageClass 'fast-storage' not found — you need to create it"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  CONGRATULATIONS! You escaped the room!"
echo "==========================================${NC}"
echo ""
echo "You fixed the storage configuration by creating"
echo "the missing StorageClass. The PVC bound and the"
echo "StatefulSet pod started successfully."
echo ""
