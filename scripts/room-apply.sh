#!/usr/bin/env bash
# room-apply.sh - Apply a room's Kubernetes manifests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ROOM_NAME="${1:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ -z "$ROOM_NAME" ]; then
    echo -e "${RED}Error: Room name required${NC}"
    echo "Usage: $0 <room-name>"
    exit 1
fi

ROOM_DIR="${PROJECT_ROOT}/rooms/${ROOM_NAME}"

if [ ! -d "$ROOM_DIR" ]; then
    echo -e "${RED}Error: Room '${ROOM_NAME}' not found${NC}"
    exit 1
fi

echo -e "${CYAN}Entering escape room: ${ROOM_NAME}${NC}"
echo ""

# Create a namespace for the room (if it doesn't exist)
NAMESPACE="escape-${ROOM_NAME}"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Apply all YAML files in the room directory
for manifest in "$ROOM_DIR"/*.yaml; do
    if [ -f "$manifest" ]; then
        echo "Applying: $(basename "$manifest")"
        kubectl apply -f "$manifest" -n "$NAMESPACE"
    fi
done

echo ""
echo -e "${GREEN}Room '${ROOM_NAME}' has been applied.${NC}"
echo ""
echo -e "${CYAN}You are now trapped! Debug the cluster to escape.${NC}"
echo ""
echo "Useful commands:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  kubectl describe pod <pod-name> -n $NAMESPACE"
echo "  kubectl logs <pod-name> -n $NAMESPACE"
echo ""
echo "When you're stuck:"
echo "  make room-objective ROOM=$ROOM_NAME  # What you need to achieve"
echo "  make room-hint ROOM=$ROOM_NAME       # Get hints"
echo "  make room-solution ROOM=$ROOM_NAME   # See the solution"
