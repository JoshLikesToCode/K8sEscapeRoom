#!/usr/bin/env bash
# kind-delete.sh - Delete the kind cluster
set -euo pipefail

CLUSTER_NAME="${1:-k8s-escape-room}"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Deleting kind cluster '${CLUSTER_NAME}'...${NC}"

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}Cluster '${CLUSTER_NAME}' does not exist.${NC}"
    exit 0
fi

kind delete cluster --name "$CLUSTER_NAME"

echo -e "${GREEN}Cluster '${CLUSTER_NAME}' deleted.${NC}"
