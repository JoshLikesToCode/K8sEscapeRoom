#!/usr/bin/env bash
# tests.sh - Validate room-configmap-missing is in expected failure state
#
# Expected state: Pod in CreateContainerConfigError due to missing ConfigMap
#
# Success criteria:
#   - Pod exists
#   - Container is in CreateContainerConfigError state
#   - ConfigMap 'app-config' does NOT exist
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-room-configmap-missing}"
POD_NAME="escape-app"
ROOM_NAME="room-configmap-missing"
CONFIGMAP_NAME="app-config"

echo -e "${CYAN}Testing room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: CreateContainerConfigError (missing ConfigMap)${NC}"
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
# Test 2: Pod is in CreateContainerConfigError state
# ============================================================================
test_start "Container is in CreateContainerConfigError"

waiting_reason=$(get_waiting_reason "$POD_NAME" "$NAMESPACE")
pod_phase=$(get_pod_phase "$POD_NAME" "$NAMESPACE")

# CreateContainerConfigError should appear in the waiting reason
if [ "$waiting_reason" = "CreateContainerConfigError" ]; then
    test_pass "waiting.reason=CreateContainerConfigError"
elif echo "$waiting_reason" | grep -qi "config"; then
    test_pass "waiting.reason=$waiting_reason (config-related)"
else
    # If pod is Running, the room was fixed
    if [ "$pod_phase" = "Running" ]; then
        dump_debug_info "$NAMESPACE"
        test_fail "Pod is Running - expected CreateContainerConfigError"
    fi
    test_warn "Unexpected state: phase=$pod_phase, waiting.reason=$waiting_reason"
fi

# ============================================================================
# Test 3: ConfigMap does NOT exist (this is the bug)
# ============================================================================
test_start "ConfigMap '$CONFIGMAP_NAME' does NOT exist"

if kubectl get configmap "$CONFIGMAP_NAME" -n "$NAMESPACE" &>/dev/null; then
    dump_debug_info "$NAMESPACE"
    test_fail "ConfigMap '$CONFIGMAP_NAME' exists - it should be missing for this room"
else
    test_pass "ConfigMap is missing (as expected)"
fi

# ============================================================================
# Test 4: Events mention the missing ConfigMap
# ============================================================================
test_start "Events mention missing ConfigMap"

if assert_event_contains "$NAMESPACE" "configmap.*not found|ConfigMap.*not found"; then
    test_pass
else
    # This is a soft check - events might not have propagated yet
    test_warn "Could not verify - events may not show the error yet"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
