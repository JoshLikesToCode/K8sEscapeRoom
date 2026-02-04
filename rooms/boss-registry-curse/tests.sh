#!/usr/bin/env bash
# tests.sh - Validate boss-registry-curse is in expected failure state
#
# Expected state: MULTIPLE FAILURES
#   1. ServiceAccount references wrong imagePullSecrets name
#   2. Pod in ImagePullBackOff (can't pull private image)
#
# Success criteria:
#   - Pod exists
#   - Pod is in ImagePullBackOff or ErrImagePull
#   - Secret "registry-credentials" EXISTS
#   - ServiceAccount references WRONG secret name
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-boss-registry-curse}"
POD_NAME="escape-app"
SERVICE_ACCOUNT="app-sa"
CORRECT_SECRET="registry-credentials"
WRONG_SECRET="registry-creds"
ROOM_NAME="boss-registry-curse"

echo -e "${CYAN}Testing boss room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: ImagePullBackOff + wrong secret reference${NC}"
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
# Test 2: Pod is in ImagePullBackOff or ErrImagePull
# ============================================================================
test_start "Pod is in ImagePullBackOff or ErrImagePull"

waiting_reason=$(get_waiting_reason "$POD_NAME" "$NAMESPACE")

if [ "$waiting_reason" = "ImagePullBackOff" ] || [ "$waiting_reason" = "ErrImagePull" ]; then
    test_pass "waiting.reason=$waiting_reason"
else
    pod_phase=$(get_pod_phase "$POD_NAME" "$NAMESPACE")
    if [ "$pod_phase" = "Running" ]; then
        dump_debug_info "$NAMESPACE"
        test_fail "Pod is Running - expected ImagePullBackOff"
    fi
    test_warn "Unexpected waiting reason: $waiting_reason (phase: $pod_phase)"
fi

# ============================================================================
# FAILURE #1: Secret EXISTS (this is the red herring)
# ============================================================================
test_start "Secret '$CORRECT_SECRET' EXISTS (red herring)"

if kubectl get secret "$CORRECT_SECRET" -n "$NAMESPACE" &>/dev/null; then
    test_pass "Secret exists (but is it being used?)"
else
    test_fail "Secret '$CORRECT_SECRET' should exist for this room"
fi

# ============================================================================
# FAILURE #2: ServiceAccount references WRONG secret
# ============================================================================
test_start "FAILURE: ServiceAccount references wrong secret '$WRONG_SECRET'"

SA_SECRET=$(kubectl get sa "$SERVICE_ACCOUNT" -n "$NAMESPACE" \
    -o jsonpath='{.imagePullSecrets[0].name}' 2>/dev/null || echo "")

if [ "$SA_SECRET" = "$WRONG_SECRET" ]; then
    test_pass "SA references '$WRONG_SECRET' (wrong, as expected)"
elif [ "$SA_SECRET" = "$CORRECT_SECRET" ]; then
    dump_debug_info "$NAMESPACE"
    test_fail "SA references correct secret '$CORRECT_SECRET' - should reference wrong name"
else
    test_warn "SA references '$SA_SECRET' - expected '$WRONG_SECRET'"
fi

# ============================================================================
# Test 5: Pod uses the misconfigured ServiceAccount
# ============================================================================
test_start "Pod uses ServiceAccount '$SERVICE_ACCOUNT'"

POD_SA=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null || echo "")

if [ "$POD_SA" = "$SERVICE_ACCOUNT" ]; then
    test_pass
else
    test_warn "Pod uses SA '$POD_SA', expected '$SERVICE_ACCOUNT'"
fi

# ============================================================================
# Test 6: Events show image pull failure
# ============================================================================
test_start "Events show image pull failure"

if assert_event_contains "$NAMESPACE" "Failed.*pull|ErrImagePull|ImagePullBackOff|pulling image"; then
    test_pass "Image pull failure events found"
else
    test_warn "Could not verify image pull events yet"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
