#!/bin/bash
# K8sEscapeRoom CLI Installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/JoshLikesToCode/K8sEscapeRoom/main/scripts/install.sh | bash
#
# Or with a specific version:
#   curl -fsSL https://raw.githubusercontent.com/JoshLikesToCode/K8sEscapeRoom/main/scripts/install.sh | bash -s -- --version 1.0.0

set -e

# Configuration
VERSION="latest"
REPO="JoshLikesToCode/K8sEscapeRoom"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="escape"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version|-v)
            VERSION="$2"
            shift 2
            ;;
        --install-dir|-d)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "K8sEscapeRoom CLI Installer"
            echo ""
            echo "Usage: install.sh [options]"
            echo ""
            echo "Options:"
            echo "  --version, -v     Install a specific version (default: latest)"
            echo "  --install-dir, -d Installation directory (default: /usr/local/bin)"
            echo "  --help, -h        Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Detect OS and architecture
detect_platform() {
    local os=""
    local arch=""

    case "$(uname -s)" in
        Linux*)     os="linux" ;;
        Darwin*)    os="osx" ;;
        CYGWIN*|MINGW*|MSYS*) os="win" ;;
        *)          echo -e "${RED}Unsupported OS: $(uname -s)${NC}"; exit 1 ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64)   arch="x64" ;;
        arm64|aarch64)  arch="arm64" ;;
        *)              echo -e "${RED}Unsupported architecture: $(uname -m)${NC}"; exit 1 ;;
    esac

    # macOS arm64 support
    if [[ "$os" == "osx" && "$arch" == "arm64" ]]; then
        echo "osx-arm64"
    elif [[ "$os" == "osx" ]]; then
        echo "osx-x64"
    elif [[ "$os" == "linux" ]]; then
        echo "linux-x64"
    elif [[ "$os" == "win" ]]; then
        echo "win-x64"
    fi
}

# Get the latest version from GitHub
get_latest_version() {
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/'
}

# Main installation
main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║   🔐 K8sEscapeRoom CLI Installer                         ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Detect platform
    local platform=$(detect_platform)
    echo -e "Detected platform: ${GREEN}${platform}${NC}"

    # Get version
    if [[ "$VERSION" == "latest" ]]; then
        echo -n "Fetching latest version... "
        VERSION=$(get_latest_version)
        if [[ -z "$VERSION" ]]; then
            echo -e "${RED}Failed to get latest version${NC}"
            exit 1
        fi
        echo -e "${GREEN}v${VERSION}${NC}"
    fi

    # Construct download URL
    local ext="tar.gz"
    [[ "$platform" == "win-x64" ]] && ext="zip"
    local url="https://github.com/${REPO}/releases/download/v${VERSION}/escape-${platform}.${ext}"

    echo -e "Download URL: ${CYAN}${url}${NC}"

    # Create temp directory
    local tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT

    # Download
    echo -n "Downloading... "
    if ! curl -fsSL "$url" -o "$tmp_dir/escape.${ext}"; then
        echo -e "${RED}Failed${NC}"
        echo -e "${RED}Could not download from: ${url}${NC}"
        echo -e "${YELLOW}Check if version v${VERSION} exists at: https://github.com/${REPO}/releases${NC}"
        exit 1
    fi
    echo -e "${GREEN}Done${NC}"

    # Extract
    echo -n "Extracting... "
    cd "$tmp_dir"
    if [[ "$ext" == "tar.gz" ]]; then
        tar -xzf "escape.${ext}"
    else
        unzip -q "escape.${ext}"
    fi
    echo -e "${GREEN}Done${NC}"

    # Install
    echo -n "Installing to ${INSTALL_DIR}... "
    if [[ -w "$INSTALL_DIR" ]]; then
        mv escape "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/escape"
    else
        sudo mv escape "$INSTALL_DIR/"
        sudo chmod +x "$INSTALL_DIR/escape"
    fi
    echo -e "${GREEN}Done${NC}"

    # Verify
    echo ""
    if command -v escape &> /dev/null; then
        echo -e "${GREEN}✓ Installation successful!${NC}"
        echo ""
        echo "Get started:"
        echo -e "  ${CYAN}escape doctor${NC}     - Check your setup"
        echo -e "  ${CYAN}escape quickstart${NC} - Start the tutorial"
        echo ""
        echo -e "Full documentation: ${CYAN}https://k8sescaperoom.dev${NC}"
    else
        echo -e "${YELLOW}Installation complete, but 'escape' is not in your PATH.${NC}"
        echo -e "Add ${INSTALL_DIR} to your PATH, or run:"
        echo -e "  ${CYAN}${INSTALL_DIR}/escape doctor${NC}"
    fi
}

main
