#!/usr/bin/env bash
# kind-create.sh - Create a kind cluster for K8sEscapeRoom
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

CLUSTER_NAME="${1:-k8s-escape-room}"
CONFIG_FILE="${PROJECT_ROOT}/kind/cluster.yaml"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Creating kind cluster '${CLUSTER_NAME}'...${NC}"

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}Cluster '${CLUSTER_NAME}' already exists.${NC}"
    echo "Use 'make cluster-down' to delete it first, or use the existing cluster."
    exit 0
fi

# Create the cluster
if [ -f "$CONFIG_FILE" ]; then
    echo "Using configuration: $CONFIG_FILE"
    kind create cluster --name "$CLUSTER_NAME" --config "$CONFIG_FILE"
else
    echo "No cluster config found, using defaults."
    kind create cluster --name "$CLUSTER_NAME"
fi

# Set kubectl context
kubectl cluster-info --context "kind-${CLUSTER_NAME}"

echo ""
echo -e "${GREEN}Cluster '${CLUSTER_NAME}' is ready!${NC}"
echo ""
echo "Next steps:"
echo "  make room-list              # See available escape rooms"
echo "  make room-apply ROOM=<name> # Enter an escape room"
