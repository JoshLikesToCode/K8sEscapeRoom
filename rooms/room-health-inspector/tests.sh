#!/usr/bin/env bash
# tests.sh - Validate room-health-inspector is in expected failure state
#
# Expected state: Pod keeps restarting due to failing liveness probe (wrong port)
#
# Success criteria:
#   - Deployment exists
#   - Pod is in CrashLoopBackOff OR has restarts > 0
#   - Liveness probe is configured with port 8080 (the bug)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-room-health-inspector}"
DEPLOYMENT_NAME="escape-app"
POD_LABEL="app=escape-app"
ROOM_NAME="room-health-inspector"

echo -e "${CYAN}Testing room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: CrashLoopBackOff (probe checking wrong port)${NC}"
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
# Test 2: Pod exists
# ============================================================================
test_start "Pod with label '$POD_LABEL' exists"

if ! wait_for_pod "$NAMESPACE" "$POD_LABEL" 30; then
    test_fail "No pod found with label '$POD_LABEL' in namespace '$NAMESPACE'"
fi

POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
test_pass "$POD_NAME"

# ============================================================================
# Test 3: Pod shows signs of probe-induced restarts
# ============================================================================
test_start "Pod is restarting (CrashLoopBackOff or high restart count)"

waiting_reason=$(get_waiting_reason "$POD_NAME" "$NAMESPACE")
restart_count=$(get_restart_count "$POD_NAME" "$NAMESPACE")
pod_phase=$(get_pod_phase "$POD_NAME" "$NAMESPACE")

if [ "$waiting_reason" = "CrashLoopBackOff" ]; then
    test_pass "waiting.reason=CrashLoopBackOff"
elif [ "$restart_count" -gt 0 ]; then
    test_pass "restartCount=$restart_count (probe is killing container)"
elif [ "$pod_phase" = "Running" ]; then
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
# Test 4: Liveness probe is configured with wrong port
# ============================================================================
test_start "Liveness probe targets port 8080 (the bug)"

PROBE_PORT=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.port}' 2>/dev/null || echo "")

if [ "$PROBE_PORT" = "8080" ]; then
    test_pass "livenessProbe.port=8080 (as expected)"
elif [ -z "$PROBE_PORT" ]; then
    test_fail "No liveness probe configured"
else
    test_fail "Liveness probe port is '$PROBE_PORT' - expected '8080' for this room"
fi

# ============================================================================
# Test 5: Events show probe failures
# ============================================================================
test_start "Events show probe failures"

if assert_event_contains "$NAMESPACE" "Unhealthy|Liveness probe failed|probe failed|connection refused"; then
    test_pass "Probe failure events found"
else
    test_warn "Could not verify probe failure events yet"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
