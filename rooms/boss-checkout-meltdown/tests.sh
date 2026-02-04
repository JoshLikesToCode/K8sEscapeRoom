#!/usr/bin/env bash
# tests.sh - Validate boss-checkout-meltdown is in expected failure state
#
# Expected state: MULTIPLE FAILURES
#   1. Service selector mismatch - no endpoints
#   2. Readiness probe on wrong port - pods not ready
#
# Success criteria:
#   - Pods exist and are Running
#   - Pods are NOT Ready (0/1)
#   - Service has 0 endpoints
#   - Events show readiness probe failures
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-boss-checkout-meltdown}"
DEPLOYMENT_NAME="checkout-api"
SERVICE_NAME="checkout-service"
POD_LABEL="app=checkout-api"
ROOM_NAME="boss-checkout-meltdown"

echo -e "${CYAN}Testing boss room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: Multiple failures (selector mismatch + probe misconfigured)${NC}"
echo ""

# ============================================================================
# Test 1: Deployment exists and has pods
# ============================================================================
test_start "Deployment '$DEPLOYMENT_NAME' exists with pods"

if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &>/dev/null; then
    test_fail "Deployment '$DEPLOYMENT_NAME' does not exist"
fi

# Wait for pods to be created
if ! wait_for_pod "$NAMESPACE" "$POD_LABEL" 30; then
    test_fail "No pods found with label '$POD_LABEL'"
fi

POD_COUNT=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" --no-headers 2>/dev/null | wc -l)
if [ "$POD_COUNT" -gt 0 ]; then
    test_pass "$POD_COUNT pod(s) found"
else
    test_fail "No pods found"
fi

# ============================================================================
# Test 2: Pods are Running (phase check)
# ============================================================================
test_start "Pods are in Running phase"

RUNNING_COUNT=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" --no-headers 2>/dev/null | grep -c "Running" || echo "0")

if [ "$RUNNING_COUNT" -gt 0 ]; then
    test_pass "$RUNNING_COUNT pod(s) Running"
else
    test_warn "No pods in Running phase yet"
fi

# ============================================================================
# FAILURE #1: Pods are NOT Ready (readiness probe failing)
# ============================================================================
test_start "FAILURE #1: Pods are NOT Ready (0/1)"

# Check if any pod shows 1/1 Ready
READY_PODS=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" --no-headers 2>/dev/null | grep -c "1/1" || echo "0")

if [ "$READY_PODS" -eq 0 ]; then
    test_pass "All pods show 0/1 Ready (probe failing as expected)"
else
    dump_debug_info "$NAMESPACE"
    test_fail "$READY_PODS pod(s) are Ready - expected 0/1 for this room"
fi

# ============================================================================
# FAILURE #2: Service has 0 endpoints (selector mismatch)
# ============================================================================
test_start "FAILURE #2: Service has 0 endpoints"

ENDPOINTS=$(kubectl get endpoints "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")

if [ -z "$ENDPOINTS" ]; then
    test_pass "No endpoints (selector mismatch as expected)"
else
    dump_debug_info "$NAMESPACE"
    test_fail "Service has endpoints ($ENDPOINTS) - should have none for this room"
fi

# ============================================================================
# Test 5: Verify selector mismatch exists
# ============================================================================
test_start "Service selector does NOT match pod labels"

POD_APP_LABEL=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.labels.app}' 2>/dev/null || echo "")
SVC_SELECTOR=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.selector.app}' 2>/dev/null || echo "")

if [ "$POD_APP_LABEL" != "$SVC_SELECTOR" ]; then
    test_pass "Pod label 'app=$POD_APP_LABEL' != Service selector 'app=$SVC_SELECTOR'"
else
    test_fail "Labels match - they should be different for this room"
fi

# ============================================================================
# Test 6: Verify readiness probe is misconfigured
# ============================================================================
test_start "Readiness probe targets wrong port (8080)"

PROBE_PORT=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}' 2>/dev/null || echo "")

if [ "$PROBE_PORT" = "8080" ]; then
    test_pass "Readiness probe port is 8080 (wrong, as expected)"
else
    test_warn "Probe port is '$PROBE_PORT' - expected 8080 for this room"
fi

# ============================================================================
# Test 7: Events show readiness probe failures
# ============================================================================
test_start "Events show readiness probe failures"

if assert_event_contains "$NAMESPACE" "Unhealthy|Readiness probe failed|probe failed"; then
    test_pass "Probe failure events found"
else
    test_warn "Could not verify probe failure events yet"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
