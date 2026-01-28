#!/usr/bin/env bash
# tools-check.sh - Verify required tools are installed
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

check_tool() {
    local tool=$1
    local install_hint=$2

    if command -v "$tool" &> /dev/null; then
        local version
        case "$tool" in
            docker)
                version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')
                ;;
            kind)
                version=$(kind --version 2>/dev/null | cut -d' ' -f3)
                ;;
            kubectl)
                version=$(kubectl version --client -o json 2>/dev/null | grep -o '"gitVersion": "[^"]*"' | cut -d'"' -f4)
                ;;
            dotnet)
                version=$(dotnet --version 2>/dev/null)
                ;;
            *)
                version="installed"
                ;;
        esac
        echo -e "${GREEN}✓${NC} $tool ($version)"
        return 0
    else
        echo -e "${RED}✗${NC} $tool - $install_hint"
        return 1
    fi
}

echo "Checking required tools..."
echo ""

errors=0

check_tool "docker" "Install from https://docs.docker.com/get-docker/" || ((errors++))
check_tool "kind" "Install from https://kind.sigs.k8s.io/docs/user/quick-start/#installation" || ((errors++))
check_tool "kubectl" "Install from https://kubernetes.io/docs/tasks/tools/" || ((errors++))

echo ""
echo "Checking optional tools..."
echo ""

check_tool "dotnet" "Install .NET 8 from https://dotnet.microsoft.com/download" || echo -e "${YELLOW}  (optional - CLI wrapper will not be available)${NC}"

echo ""

if [ $errors -gt 0 ]; then
    echo -e "${RED}Missing $errors required tool(s). Please install them before continuing.${NC}"
    exit 1
fi

echo -e "${GREEN}All required tools are installed!${NC}"

# Check Docker is running
if ! docker info &> /dev/null; then
    echo ""
    echo -e "${RED}Docker is installed but not running. Please start Docker.${NC}"
    exit 1
fi

echo -e "${GREEN}Docker daemon is running.${NC}"
