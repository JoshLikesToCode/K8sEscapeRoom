#!/usr/bin/env bash
# escape-tests.sh - Validate boss-registry-curse has been ESCAPED (fixed)
#
# Success criteria (ALL must pass):
#   - ServiceAccount references correct secret
#   - Pod is Running (with a working image)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-boss-registry-curse"
POD_NAME="escape-app"
SERVICE_ACCOUNT="app-sa"
CORRECT_SECRET="registry-credentials"

echo "=== Testing boss-registry-curse (escaped/fixed state) ==="
echo ""

# ============================================================================
# Test 1: ServiceAccount references correct secret
# ============================================================================
test_start "ServiceAccount references correct secret"

SA_SECRET=$(kubectl get sa "$SERVICE_ACCOUNT" -n "$NAMESPACE" \
    -o jsonpath='{.imagePullSecrets[0].name}' 2>/dev/null || echo "")

if [ "$SA_SECRET" = "$CORRECT_SECRET" ]; then
    test_pass "SA references '$CORRECT_SECRET'"
else
    test_fail "SA still references '$SA_SECRET' - should be '$CORRECT_SECRET'"
fi

# ============================================================================
# Test 2: Pod exists
# ============================================================================
test_start "Pod '$POD_NAME' exists"

if assert_pod_exists "$POD_NAME" "$NAMESPACE"; then
    test_pass
else
    test_fail "Pod '$POD_NAME' does not exist - may need to recreate it"
fi

# ============================================================================
# Test 3: Pod is Running
# ============================================================================
test_start "Pod is Running"

PHASE=$(get_pod_phase "$POD_NAME" "$NAMESPACE")

if [ "$PHASE" = "Running" ]; then
    test_pass "$PHASE"
else
    waiting_reason=$(get_waiting_reason "$POD_NAME" "$NAMESPACE")
    if [ "$waiting_reason" = "ImagePullBackOff" ] || [ "$waiting_reason" = "ErrImagePull" ]; then
        test_fail "Pod still in $waiting_reason - need to use a working image"
    else
        test_fail "Pod is in '$PHASE' state, expected 'Running'"
    fi
fi

# ============================================================================
# Test 4: Pod is Ready
# ============================================================================
test_start "Pod is Ready"

READY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")

if [ "$READY" = "True" ]; then
    test_pass
else
    test_fail "Pod is not Ready"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  CONGRATULATIONS! You escaped the boss room!"
echo "==========================================${NC}"
echo ""
echo "You successfully fixed the registry configuration:"
echo "  1. Corrected the ServiceAccount imagePullSecrets reference"
echo "  2. Used a working container image"
echo ""
echo "The curse is lifted!"
echo ""
