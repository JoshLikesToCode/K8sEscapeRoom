#!/usr/bin/env bash
# tests.sh - Validate room-probe-doom is in expected failure state
#
# Expected state: Pod keeps restarting due to failing liveness probe
#
# Success criteria:
#   - Pod exists
#   - Pod is in CrashLoopBackOff OR has restarts > 0
#   - Liveness probe is configured with /healthz path
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-room-probe-doom}"
POD_NAME="escape-app"
ROOM_NAME="room-probe-doom"

echo -e "${CYAN}Testing room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: CrashLoopBackOff (failing liveness probe)${NC}"
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
# Test 2: Pod shows signs of probe-induced restarts
# ============================================================================
test_start "Pod is restarting (CrashLoopBackOff or high restart count)"

waiting_reason=$(get_waiting_reason "$POD_NAME" "$NAMESPACE")
restart_count=$(get_restart_count "$POD_NAME" "$NAMESPACE")
pod_phase=$(get_pod_phase "$POD_NAME" "$NAMESPACE")

# The pod might be in CrashLoopBackOff, or Running with restarts
if [ "$waiting_reason" = "CrashLoopBackOff" ]; then
    test_pass "waiting.reason=CrashLoopBackOff"
elif [ "$restart_count" -gt 0 ]; then
    test_pass "restartCount=$restart_count (probe is killing container)"
elif [ "$pod_phase" = "Running" ]; then
    # Pod might be in brief running state between probe failures
    # Wait a bit and check again
    sleep 5
    restart_count=$(get_restart_count "$POD_NAME" "$NAMESPACE")
    if [ "$restart_count" -gt 0 ]; then
        test_pass "restartCount=$restart_count (probe failures detected)"
    else
        test_warn "Pod is running with 0 restarts - probe may not have failed yet"
    fi
else
    test_warn "Unexpected state: phase=$pod_phase, restarts=$restart_count"
fi

# ============================================================================
# Test 3: Liveness probe is configured with wrong path
# ============================================================================
test_start "Liveness probe targets /healthz (the bug)"

PROBE_PATH=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].livenessProbe.httpGet.path}' 2>/dev/null || echo "")

if [ "$PROBE_PATH" = "/healthz" ]; then
    test_pass "livenessProbe.path=/healthz (as expected)"
elif [ -z "$PROBE_PATH" ]; then
    test_fail "No liveness probe configured"
else
    test_fail "Liveness probe path is '$PROBE_PATH' - expected '/healthz' for this room"
fi

# ============================================================================
# Test 4: Events show probe failures
# ============================================================================
test_start "Events show probe failures"

if assert_event_contains "$NAMESPACE" "Unhealthy|Liveness probe failed|probe failed"; then
    test_pass "Probe failure events found"
else
    # Might be too early for events
    test_warn "Could not verify probe failure events yet"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
