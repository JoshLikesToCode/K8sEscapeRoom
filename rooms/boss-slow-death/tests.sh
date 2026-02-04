#!/usr/bin/env bash
# tests.sh - Validate boss-slow-death is in expected failure state
#
# Expected state: MULTIPLE FAILURES causing restarts
#   1. Memory limit too low (OOMKilled)
#   2. Liveness probe too aggressive (probe-kill)
#
# Success criteria:
#   - Pod exists
#   - Pod is restarting (CrashLoopBackOff or high restart count)
#   - Memory limit is too low (<= 32Mi)
#   - Liveness probe failureThreshold is 1 (too aggressive)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-boss-slow-death}"
POD_NAME="escape-app"
ROOM_NAME="boss-slow-death"

echo -e "${CYAN}Testing boss room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: OOMKilled + aggressive probe kills${NC}"
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
# Test 2: Pod is restarting
# ============================================================================
test_start "Pod is restarting (CrashLoopBackOff or restarts > 0)"

waiting_reason=$(get_waiting_reason "$POD_NAME" "$NAMESPACE")
restart_count=$(get_restart_count "$POD_NAME" "$NAMESPACE")

if [ "$waiting_reason" = "CrashLoopBackOff" ]; then
    test_pass "waiting.reason=CrashLoopBackOff"
elif [ "$restart_count" -gt 0 ]; then
    test_pass "restartCount=$restart_count"
else
    # Pod might still be on first attempt
    sleep 10
    restart_count=$(get_restart_count "$POD_NAME" "$NAMESPACE")
    if [ "$restart_count" -gt 0 ]; then
        test_pass "restartCount=$restart_count (after waiting)"
    else
        test_warn "No restarts yet - pod may not have failed yet"
    fi
fi

# ============================================================================
# FAILURE #1: Memory limit too low
# ============================================================================
test_start "FAILURE #1: Memory limit is too low (<= 32Mi)"

MEMORY_LIMIT=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo "")

# Extract numeric value (remove Mi suffix)
MEMORY_VALUE="${MEMORY_LIMIT%Mi}"

if [ -n "$MEMORY_VALUE" ] && [ "$MEMORY_VALUE" -le 32 ] 2>/dev/null; then
    test_pass "Memory limit is ${MEMORY_LIMIT} (too low, as expected)"
else
    test_warn "Memory limit is ${MEMORY_LIMIT} - expected <= 32Mi"
fi

# ============================================================================
# FAILURE #2: Liveness probe too aggressive
# ============================================================================
test_start "FAILURE #2: Liveness probe failureThreshold is 1"

FAILURE_THRESHOLD=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].livenessProbe.failureThreshold}' 2>/dev/null || echo "")

if [ "$FAILURE_THRESHOLD" = "1" ]; then
    test_pass "failureThreshold=1 (too aggressive, as expected)"
else
    test_warn "failureThreshold=$FAILURE_THRESHOLD - expected 1"
fi

# ============================================================================
# Test 5: Check for failure evidence in events/state
# ============================================================================
test_start "Evidence of failures in events or container state"

# Check for OOMKilled in last terminated state
LAST_REASON=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}' 2>/dev/null || echo "")

# Check events for probe failures or OOM
EVENTS=$(kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' 2>/dev/null || echo "")

if [ "$LAST_REASON" = "OOMKilled" ]; then
    test_pass "Last termination: OOMKilled"
elif [ "$LAST_REASON" = "Error" ]; then
    test_pass "Last termination: Error (likely probe-kill)"
elif echo "$EVENTS" | grep -qi "oom\|unhealthy\|probe failed"; then
    test_pass "Failure evidence in events"
else
    test_warn "Could not verify failure evidence yet"
fi

# ============================================================================
# Test 6: Verify probe timeout is too short
# ============================================================================
test_start "Liveness probe timeout is too short (1s)"

TIMEOUT=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].livenessProbe.timeoutSeconds}' 2>/dev/null || echo "")

if [ "$TIMEOUT" = "1" ]; then
    test_pass "timeoutSeconds=1 (too short, as expected)"
else
    test_warn "timeoutSeconds=$TIMEOUT - expected 1"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
