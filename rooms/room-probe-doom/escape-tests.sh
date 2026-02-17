#!/usr/bin/env bash
# escape-tests.sh - Validate that room-probe-doom has been ESCAPED (fixed)
#
# Success criteria:
# - Pod is Running and Ready
# - Liveness probe exists and is not targeting port 8080
# - Restart count is stable (not increasing)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-room-probe-doom"
DEPLOYMENT_NAME="escape-app"
POD_LABEL="app=escape-app"

echo "=== Testing room-probe-doom (escaped/fixed state) ==="
echo ""

# ============================================================================
# Test 1: Pod is Running
# ============================================================================
test_start "Pod is Running"

POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$POD_NAME" ]; then
    test_fail "No pod found with label '$POD_LABEL'"
fi

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
# Test 3: Liveness probe exists and has been fixed
# ============================================================================
test_start "Liveness probe exists and is not targeting port 8080"

PROBE_PORT=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.port}' 2>/dev/null || echo "")

if [ -z "$PROBE_PORT" ]; then
    test_fail "Liveness probe was removed - it should be fixed, not removed"
elif [ "$PROBE_PORT" = "8080" ]; then
    test_fail "Liveness probe still targets port 8080"
else
    test_pass "Liveness probe port: $PROBE_PORT"
fi

# ============================================================================
# Test 4: Pod is stable (restarts not increasing)
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

echo ""
echo -e "${GREEN}=========================================="
echo "  CONGRATULATIONS! You escaped the room!"
echo "==========================================${NC}"
echo ""
echo "You successfully fixed the misconfigured liveness probe port"
echo "so Kubernetes stops killing your healthy container."
echo ""
