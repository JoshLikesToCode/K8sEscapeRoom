#!/usr/bin/env bash
# escape-tests.sh - Validate final-cascading-outage has been ESCAPED (fixed)
#
# Success criteria (ALL must pass):
#   - CronJob suspended or deleted
#   - All 3 Deployments have pods Running + Ready (1/1)
#   - All 3 Services have endpoints
#   - No NetworkPolicy named deny-api-ingress exists
#   - No pods in OOMKilled/CrashLoopBackOff state
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="${NAMESPACE:-escape-final-cascading-outage}"
ROOM_NAME="final-cascading-outage"

echo ""
echo -e "${DIM}Verifying incident resolution...${NC}"
echo ""

# ============================================================================
# Test 1: CronJob suspended or deleted
# ============================================================================
test_start "CronJob escalation-agent is suspended or deleted"

if ! kubectl get cronjob escalation-agent -n "$NAMESPACE" &>/dev/null; then
    test_pass "CronJob deleted"
else
    SUSPENDED=$(kubectl get cronjob escalation-agent -n "$NAMESPACE" -o jsonpath='{.spec.suspend}' 2>/dev/null || echo "false")
    if [ "$SUSPENDED" = "true" ]; then
        test_pass "CronJob suspended"
    else
        test_fail "CronJob escalation-agent is still active — suspend or delete it first"
    fi
fi

# ============================================================================
# Test 2: frontend pods Running and Ready
# ============================================================================
test_start "frontend pods Running and Ready (1/1)"

READY=$(kubectl get pods -n "$NAMESPACE" -l "app=web-frontend" --no-headers 2>/dev/null | grep -c "1/1.*Running" || true)
if [ "$READY" -gt 0 ]; then
    test_pass "$READY pod(s) Ready"
else
    test_fail "No frontend pods are Ready — check deployment and pod status"
fi

# ============================================================================
# Test 3: frontend-svc has endpoints
# ============================================================================
test_start "frontend-svc has endpoints"

ENDPOINTS=$(kubectl get endpoints frontend-svc -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")
if [ -n "$ENDPOINTS" ]; then
    test_pass "endpoints found"
else
    test_fail "frontend-svc has no endpoints — check the Service selector"
fi

# ============================================================================
# Test 4: api-server pods Running and Ready
# ============================================================================
test_start "api-server pods Running and Ready (1/1)"

READY=$(kubectl get pods -n "$NAMESPACE" -l "app=api-server" --no-headers 2>/dev/null | grep -c "1/1.*Running" || true)
if [ "$READY" -gt 0 ]; then
    test_pass "$READY pod(s) Ready"
else
    test_fail "No api-server pods are Ready — check Secret, readiness probe, and NetworkPolicy"
fi

# ============================================================================
# Test 5: api-svc has endpoints
# ============================================================================
test_start "api-svc has endpoints"

ENDPOINTS=$(kubectl get endpoints api-svc -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")
if [ -n "$ENDPOINTS" ]; then
    test_pass "endpoints found"
else
    test_fail "api-svc has no endpoints"
fi

# ============================================================================
# Test 6: database pods Running and Ready
# ============================================================================
test_start "database pods Running and Ready (1/1)"

READY=$(kubectl get pods -n "$NAMESPACE" -l "app=database" --no-headers 2>/dev/null | grep -c "1/1.*Running" || true)
if [ "$READY" -gt 0 ]; then
    test_pass "$READY pod(s) Ready"
else
    test_fail "No database pods are Ready — check memory limits (CronJob may have set them to 4Mi)"
fi

# ============================================================================
# Test 7: database-svc has endpoints
# ============================================================================
test_start "database-svc has endpoints"

ENDPOINTS=$(kubectl get endpoints database-svc -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")
if [ -n "$ENDPOINTS" ]; then
    test_pass "endpoints found"
else
    test_fail "database-svc has no endpoints"
fi

# ============================================================================
# Test 8: No deny-api-ingress NetworkPolicy
# ============================================================================
test_start "No deny-api-ingress NetworkPolicy exists"

if kubectl get networkpolicy deny-api-ingress -n "$NAMESPACE" &>/dev/null; then
    test_fail "NetworkPolicy deny-api-ingress still exists — delete it"
else
    test_pass "NetworkPolicy removed"
fi

# ============================================================================
# Test 9: No pods in error states
# ============================================================================
test_start "No pods in OOMKilled or CrashLoopBackOff state"

ERROR_PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep -cE "OOMKilled|CrashLoopBackOff|CreateContainerConfigError|Error" || true)
if [ "$ERROR_PODS" -eq 0 ]; then
    test_pass "No pods in error state"
else
    test_fail "$ERROR_PODS pod(s) in error state"
fi

# ============================================================================
# Victory
# ============================================================================

# Brief pause for dramatic effect before the reveal
sleep 1

echo ""
echo ""
echo -e "${GREEN}  ======================================================================${NC}"
echo -e "${GREEN}  ||                                                                  ||${NC}"
echo -e "${GREEN}  ||${NC}${BOLD}    _  ______     _____ ____   ___                               ${NC}${GREEN}||${NC}"
echo -e "${GREEN}  ||${NC}${BOLD}   | |/ / __ \   | ____/ ___| / _ \                              ${NC}${GREEN}||${NC}"
echo -e "${GREEN}  ||${NC}${BOLD}   | ' /| |  | | |  _| \___ \| | |_|__ _ _ __   ___             ${NC}${GREEN}||${NC}"
echo -e "${GREEN}  ||${NC}${BOLD}   | . \| |__| | | |___ ___) | |_| / _\` | '_ \ / _ \\            ${NC}${GREEN}||${NC}"
echo -e "${GREEN}  ||${NC}${BOLD}   |_|\_\\\\____/  |_____|____/ \\___/\\__,_| .__/\\___/            ${NC}${GREEN}||${NC}"
echo -e "${GREEN}  ||${NC}${BOLD}                                        |_|                      ${NC}${GREEN}||${NC}"
echo -e "${GREEN}  ||${NC}${BOLD}   ____                       _      _           _  _  _         ${NC}${GREEN}||${NC}"
echo -e "${GREEN}  ||${NC}${BOLD}  / ___|___  _ __ ___  _ __ | | ___| |_ ___  __| || || |        ${NC}${GREEN}||${NC}"
echo -e "${GREEN}  ||${NC}${BOLD} | |   / _ \\| '_ \` _ \\| '_ \\| |/ _ \\ __/ _ \\/ _\` || || |_       ${NC}${GREEN}||${NC}"
echo -e "${GREEN}  ||${NC}${BOLD} | |__| (_) | | | | | | |_) | |  __/ ||  __/ (_| ||__   _|      ${NC}${GREEN}||${NC}"
echo -e "${GREEN}  ||${NC}${BOLD}  \\____\\___/|_| |_| |_| .__/|_|\\___|\\__\\___|\\__,_|   |_|        ${NC}${GREEN}||${NC}"
echo -e "${GREEN}  ||${NC}${BOLD}                       |_|                                       ${NC}${GREEN}||${NC}"
echo -e "${GREEN}  ||                                                                  ||${NC}"
echo -e "${GREEN}  ======================================================================${NC}"
echo ""
echo ""
echo -e "${BOLD}  You have completed K8s Escape Room.${NC}"
echo ""
echo -e "  ${GREEN}+${NC} Neutralized the rogue escalation-agent CronJob"
echo -e "  ${GREEN}+${NC} Fixed the frontend service selector mismatch"
echo -e "  ${GREEN}+${NC} Created the missing api-secrets Secret"
echo -e "  ${GREEN}+${NC} Repaired readiness probe, NetworkPolicy, and memory limits"
echo -e "  ${GREEN}+${NC} Restored all three tiers to full operation"
echo ""
echo -e "  ${DIM}10 rooms. 2 boss rooms. 1 final boss. 0 remaining.${NC}"
echo ""
echo -e "  ${CYAN}The incident is resolved. The pager is silent.${NC}"
echo -e "  ${CYAN}Go touch grass.${NC}"
echo ""
echo ""

finish_tests
