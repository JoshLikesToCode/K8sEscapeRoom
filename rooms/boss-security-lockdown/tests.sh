#!/usr/bin/env bash
# tests.sh - Validate boss-security-lockdown is in expected failure state
#
# Expected state: MULTIPLE FAILURES (layered)
#   1. runAsNonRoot: true but no runAsUser → CreateContainerConfigError
#   2. readOnlyRootFilesystem: true without writable volumes (hidden until #1 fixed)
#
# Success criteria:
#   - Deployment exists
#   - Pod is NOT running (CreateContainerConfigError or waiting)
#   - SecurityContext has runAsNonRoot: true
#   - SecurityContext has readOnlyRootFilesystem: true
#   - No runAsUser is set
#   - Events show security context error
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-boss-security-lockdown}"
DEPLOYMENT_NAME="escape-app"
POD_LABEL="app=escape-app"
ROOM_NAME="boss-security-lockdown"

echo -e "${CYAN}Testing boss room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: Layered failures (runAsNonRoot + readOnlyRootFilesystem)${NC}"
echo ""

# ============================================================================
# Test 1: Deployment exists
# ============================================================================
test_start "Deployment '$DEPLOYMENT_NAME' exists"

if kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &>/dev/null; then
    test_pass "Deployment found"
else
    test_fail "Deployment '$DEPLOYMENT_NAME' does not exist"
fi

# ============================================================================
# Test 2: Pod exists
# ============================================================================
test_start "Pod exists with label '$POD_LABEL'"

if wait_for_pod "$NAMESPACE" "$POD_LABEL" 30; then
    POD_COUNT=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" --no-headers 2>/dev/null | wc -l)
    test_pass "$POD_COUNT pod(s) found"
else
    test_fail "No pods found with label '$POD_LABEL'"
fi

# ============================================================================
# Test 3: Pod is NOT Running/Ready (should be in error state)
# ============================================================================
test_start "FAILURE: Pod is NOT Running and Ready"

POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

# Give the pod a moment to reach its error state
sleep 3

READY_PODS=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" --no-headers 2>/dev/null | grep -c "1/1.*Running" || true)

if [ "$READY_PODS" -eq 0 ]; then
    STATUS=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" --no-headers 2>/dev/null | awk '{print $3}' | head -1)
    test_pass "Pod is not ready (status: $STATUS)"
else
    dump_debug_info "$NAMESPACE"
    test_fail "Pod is Running and Ready — expected failure state"
fi

# ============================================================================
# Test 4: SecurityContext has runAsNonRoot: true
# ============================================================================
test_start "SecurityContext has runAsNonRoot: true"

RUN_AS_NON_ROOT=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].securityContext.runAsNonRoot}' 2>/dev/null || echo "")

if [ "$RUN_AS_NON_ROOT" = "true" ]; then
    test_pass "runAsNonRoot is true"
else
    test_fail "runAsNonRoot is '$RUN_AS_NON_ROOT' — expected 'true'"
fi

# ============================================================================
# Test 5: SecurityContext has readOnlyRootFilesystem: true
# ============================================================================
test_start "SecurityContext has readOnlyRootFilesystem: true"

READ_ONLY=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null || echo "")

if [ "$READ_ONLY" = "true" ]; then
    test_pass "readOnlyRootFilesystem is true"
else
    test_fail "readOnlyRootFilesystem is '$READ_ONLY' — expected 'true'"
fi

# ============================================================================
# Test 6: No runAsUser is set (this is the bug)
# ============================================================================
test_start "No runAsUser is set (this is Bug #1)"

RUN_AS_USER=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].securityContext.runAsUser}' 2>/dev/null || echo "")

if [ -z "$RUN_AS_USER" ]; then
    test_pass "runAsUser is not set"
else
    test_fail "runAsUser is set to '$RUN_AS_USER' — should not be set for this room"
fi

# ============================================================================
# Test 7: Events show security context error
# ============================================================================
test_start "Events show runAsNonRoot error"

# Wait a moment for events to populate
sleep 2

if assert_event_contains "$NAMESPACE" "runAsNonRoot|run as root|SecurityContext"; then
    test_pass "Security context error events found"
else
    test_warn "Could not verify security context error events yet (may need more time)"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
