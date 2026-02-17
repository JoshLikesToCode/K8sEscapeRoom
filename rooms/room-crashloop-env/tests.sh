#!/usr/bin/env bash
# tests.sh - Validate room-crashloop-env is in expected failure state
#
# Expected state: Pod in CrashLoopBackOff due to missing DATABASE_URL env var
#
# Success criteria:
#   - Deployment exists
#   - Pod exists (via label selector)
#   - Container is in CrashLoopBackOff OR has restarts > 0
#   - Logs mention DATABASE_URL
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-room-crashloop-env}"
POD_LABEL="app=escape-app"
DEPLOYMENT_NAME="escape-app"
ROOM_NAME="room-crashloop-env"

echo -e "${CYAN}Testing room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: CrashLoopBackOff (missing DATABASE_URL)${NC}"
echo ""

# ============================================================================
# Test 1: Deployment exists
# ============================================================================
test_start "Deployment '$DEPLOYMENT_NAME' exists"

if kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &>/dev/null; then
    test_pass
else
    test_fail "Deployment '$DEPLOYMENT_NAME' does not exist in namespace '$NAMESPACE'"
fi

# ============================================================================
# Test 2: Pod exists (via label selector)
# ============================================================================
test_start "Pod with label '$POD_LABEL' exists"

POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -n "$POD_NAME" ]; then
    test_pass "$POD_NAME"
else
    test_fail "No pod found with label '$POD_LABEL' in namespace '$NAMESPACE'"
fi

# ============================================================================
# Test 3: Pod is in CrashLoopBackOff state
# ============================================================================
test_start "Container is in CrashLoopBackOff"

waiting_reason=$(get_waiting_reason "$POD_NAME" "$NAMESPACE")
restart_count=$(get_restart_count "$POD_NAME" "$NAMESPACE")
terminated_reason=$(get_terminated_reason "$POD_NAME" "$NAMESPACE")
pod_phase=$(get_pod_phase "$POD_NAME" "$NAMESPACE")

# CrashLoopBackOff manifests in different ways depending on timing:
# 1. waiting.reason = "CrashLoopBackOff" (in backoff period)
# 2. restartCount > 0 (container has crashed and restarted)
# 3. terminated.reason = "Error" (container just crashed)

if [ "$waiting_reason" = "CrashLoopBackOff" ]; then
    test_pass "waiting.reason=CrashLoopBackOff"
elif [ "$restart_count" -gt 0 ]; then
    test_pass "restartCount=$restart_count"
elif [ "$terminated_reason" = "Error" ]; then
    test_pass "terminated.reason=Error"
elif [ "$pod_phase" = "Failed" ]; then
    test_pass "phase=Failed"
else
    # If pod is Running with 0 restarts, it was fixed - that's a failure
    if [ "$pod_phase" = "Running" ] && [ "$restart_count" -eq 0 ]; then
        dump_debug_info "$NAMESPACE"
        test_fail "Pod is Running successfully with 0 restarts - expected CrashLoopBackOff"
    fi
    # Otherwise, might still be starting up
    test_warn "Unexpected state: phase=$pod_phase, restarts=$restart_count"
fi

# ============================================================================
# Test 4: Error message mentions DATABASE_URL
# ============================================================================
test_start "Logs mention 'DATABASE_URL'"

if assert_logs_contain "$POD_NAME" "$NAMESPACE" "DATABASE_URL"; then
    test_pass
else
    # This is a soft check - logs might not be available yet
    test_warn "Could not verify - logs may not be available yet"
fi

# ============================================================================
# Test 5: Verify the root cause (missing env var)
# ============================================================================
test_start "DATABASE_URL env var is NOT set"

env_value=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DATABASE_URL")].value}' 2>/dev/null || echo "")

if [ -z "$env_value" ]; then
    test_pass "env var is missing (as expected)"
else
    dump_debug_info "$NAMESPACE"
    test_fail "DATABASE_URL is set to '$env_value' - should be missing for this room"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
