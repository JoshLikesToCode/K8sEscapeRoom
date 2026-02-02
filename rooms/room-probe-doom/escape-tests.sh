#!/usr/bin/env bash
# escape-tests.sh - Validate that room-probe-doom has been ESCAPED (fixed)
#
# Success criteria:
# - Pod is Running and Ready
# - Restart count is stable (not increasing)
# - Liveness probe is passing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-room-probe-doom"
POD_NAME="escape-app"

echo "=== Testing room-probe-doom (escaped/fixed state) ==="
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
# Test 2: Pod is Ready (probes passing)
# ============================================================================
test_start "Pod is Ready (probes passing)"

READY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
if [ "$READY" = "True" ]; then
    test_pass
else
    test_fail "Pod is not Ready - probes may still be failing"
fi

# ============================================================================
# Test 3: Pod is stable (restarts not increasing)
# ============================================================================
test_start "Pod is stable (no new restarts)"

RESTARTS_BEFORE=$(get_restart_count "$POD_NAME" "$NAMESPACE")
echo -n "(waiting 10s to verify stability)... "
sleep 10
RESTARTS_AFTER=$(get_restart_count "$POD_NAME" "$NAMESPACE")

if [ "$RESTARTS_BEFORE" = "$RESTARTS_AFTER" ]; then
    test_pass "Restart count stable at $RESTARTS_AFTER"
else
    test_fail "Restart count increased from $RESTARTS_BEFORE to $RESTARTS_AFTER"
fi

# ============================================================================
# Test 4: Probe configuration has been fixed
# ============================================================================
test_start "Liveness probe path is no longer /healthz"

PROBE_PATH=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].livenessProbe.httpGet.path}' 2>/dev/null || echo "")

if [ -z "$PROBE_PATH" ]; then
    test_pass "Liveness probe removed"
elif [ "$PROBE_PATH" != "/healthz" ]; then
    test_pass "Liveness probe path changed to '$PROBE_PATH'"
else
    test_fail "Liveness probe still targets /healthz"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  CONGRATULATIONS! You escaped the room!"
echo "==========================================${NC}"
echo ""
echo "You successfully fixed the misconfigured liveness probe"
echo "that was causing Kubernetes to repeatedly kill your container."
echo ""
