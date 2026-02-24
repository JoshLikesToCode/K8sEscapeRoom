#!/usr/bin/env bash
# tests.sh - Validate final-cascading-outage is in expected failure state
#
# Expected state (t=0, before CronJob runs):
#   1. frontend pods Running but frontend-svc has 0 endpoints (selector mismatch)
#   2. api-server pods in CreateContainerConfigError (missing Secret)
#   3. database pods Running and Ready (healthy at t=0)
#   4. escalation-agent CronJob exists and is NOT suspended
#   5. escalation-agent ServiceAccount and Role exist
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-final-cascading-outage}"
ROOM_NAME="final-cascading-outage"

echo -e "${CYAN}Testing boss room: ${ROOM_NAME}${NC}"
echo ""
echo -e "${RED}  _____ ___ _  _   _   _      ___  ___  ___ ___ ${NC}"
echo -e "${RED} |  ___|_ _| \| | /_\ | |    | _ )/ _ \/ __/ __|${NC}"
echo -e "${RED} | |_   | || .\` |/ _ \| |__  | _ \ (_) \__ \__ \\\\${NC}"
echo -e "${RED} |_|   |___|_|\_/_/ \_\____| |___/\___/|___/___/${NC}"
echo ""
echo -e "${RED} C A S C A D I N G   O U T A G E${NC}"
echo ""
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Validating broken state...${NC}"
echo ""

# ============================================================================
# Test 1: frontend Deployment exists with Running pods
# ============================================================================
test_start "frontend Deployment exists with Running pods"

if ! kubectl get deployment frontend -n "$NAMESPACE" &>/dev/null; then
    test_fail "Deployment 'frontend' does not exist"
fi

if ! wait_for_pod "$NAMESPACE" "app=web-frontend" 30; then
    test_fail "No frontend pods found with label 'app=web-frontend'"
fi

RUNNING=$(kubectl get pods -n "$NAMESPACE" -l "app=web-frontend" --no-headers 2>/dev/null | grep -c "Running" || true)
if [ "$RUNNING" -gt 0 ]; then
    test_pass "$RUNNING pod(s) Running"
else
    test_warn "No frontend pods in Running phase yet"
fi

# ============================================================================
# Test 2: frontend-svc has 0 endpoints (selector mismatch)
# ============================================================================
test_start "FAILURE #1: frontend-svc has 0 endpoints (selector mismatch)"

ENDPOINTS=$(kubectl get endpoints frontend-svc -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")

if [ -z "$ENDPOINTS" ]; then
    test_pass "No endpoints (selector mismatch as expected)"
else
    dump_debug_info "$NAMESPACE"
    test_fail "frontend-svc has endpoints ($ENDPOINTS) — should have none"
fi

# ============================================================================
# Test 3: api-server Deployment exists
# ============================================================================
test_start "api-server Deployment exists"

if kubectl get deployment api-server -n "$NAMESPACE" &>/dev/null; then
    REPLICAS=$(kubectl get deployment api-server -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
    test_pass "exists with $REPLICAS replicas"
else
    test_fail "Deployment 'api-server' does not exist"
fi

# ============================================================================
# Test 4: api-server pods in CreateContainerConfigError
# ============================================================================
test_start "FAILURE #2: api-server pods in CreateContainerConfigError"

if wait_for_waiting_reason "$NAMESPACE" "app=api-server" "CreateContainerConfigError" 30; then
    test_pass "CreateContainerConfigError detected"
else
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "app=api-server" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$POD_NAME" ]; then
        REASON=$(get_waiting_reason "$POD_NAME" "$NAMESPACE")
        test_warn "Expected CreateContainerConfigError but got: '$REASON'"
    else
        test_warn "No api-server pods found yet"
    fi
fi

# ============================================================================
# Test 5: database Deployment exists with Running + Ready pods
# ============================================================================
test_start "database Deployment exists with Running and Ready pods"

if ! kubectl get deployment database -n "$NAMESPACE" &>/dev/null; then
    test_fail "Deployment 'database' does not exist"
fi

if ! wait_for_pod "$NAMESPACE" "app=database" 30; then
    test_fail "No database pods found"
fi

if wait_for_condition "$NAMESPACE" "app=database" "Ready" "True" 30; then
    test_pass "database pods Running and Ready"
else
    test_warn "database pods not Ready yet"
fi

# ============================================================================
# Test 6: escalation-agent CronJob exists and is NOT suspended
# ============================================================================
test_start "escalation-agent CronJob exists and is NOT suspended"

if ! kubectl get cronjob escalation-agent -n "$NAMESPACE" &>/dev/null; then
    test_fail "CronJob 'escalation-agent' does not exist"
fi

SUSPENDED=$(kubectl get cronjob escalation-agent -n "$NAMESPACE" -o jsonpath='{.spec.suspend}' 2>/dev/null || echo "false")
if [ "$SUSPENDED" = "true" ]; then
    test_fail "CronJob is suspended — should be active for this room"
else
    test_pass "CronJob is active"
fi

# ============================================================================
# Test 7: escalation-agent ServiceAccount and Role exist
# ============================================================================
test_start "escalation-agent ServiceAccount and Role exist"

SA_EXISTS=$(kubectl get serviceaccount escalation-agent -n "$NAMESPACE" &>/dev/null && echo "yes" || echo "no")
ROLE_EXISTS=$(kubectl get role escalation-agent -n "$NAMESPACE" &>/dev/null && echo "yes" || echo "no")

if [ "$SA_EXISTS" = "yes" ] && [ "$ROLE_EXISTS" = "yes" ]; then
    test_pass "ServiceAccount and Role both exist"
elif [ "$SA_EXISTS" = "yes" ]; then
    test_warn "ServiceAccount exists but Role is missing"
elif [ "$ROLE_EXISTS" = "yes" ]; then
    test_warn "Role exists but ServiceAccount is missing"
else
    test_fail "Neither ServiceAccount nor Role exist"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
