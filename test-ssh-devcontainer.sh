#!/bin/bash

echo "🔍 SSH Devcontainer Test Script"
echo "==============================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}📋 Current Environment Status:${NC}"
echo "User: $(whoami)"
echo "Home: $HOME"
echo "PWD: $(pwd)"
echo "SSH_CLIENT: $SSH_CLIENT"
echo "SSH_CONNECTION: $SSH_CONNECTION"

echo ""
echo -e "${BLUE}🔑 SSH Service Status:${NC}"
if systemctl is-active --quiet ssh 2>/dev/null || service ssh status >/dev/null 2>&1; then
    echo -e "${GREEN}✅ SSH service is running${NC}"
else
    echo -e "${YELLOW}⚠️  SSH service status unclear (may be managed by Codespaces)${NC}"
fi

echo ""
echo -e "${BLUE}🌐 Network Connectivity:${NC}"
if command -v curl >/dev/null 2>&1; then
    if curl -s --connect-timeout 5 https://github.com >/dev/null; then
        echo -e "${GREEN}✅ Internet connectivity working${NC}"
    else
        echo -e "${RED}❌ No internet connectivity${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  curl not available${NC}"
fi

echo ""
echo -e "${BLUE}📁 File System Access:${NC}"
if [ -w "/workspaces/classified" ]; then
    echo -e "${GREEN}✅ Workspace is writable${NC}"
else
    echo -e "${RED}❌ Workspace is not writable${NC}"
fi

echo ""
echo -e "${BLUE}🔧 Basic Tools Check:${NC}"
for tool in git node bun; do
    if command -v $tool >/dev/null 2>&1; then
        version=$($tool --version 2>/dev/null | head -n1 || echo "version unknown")
        echo -e "${GREEN}✅ $tool: $version${NC}"
    else
        echo -e "${RED}❌ $tool: not found${NC}"
    fi
done

echo ""
echo -e "${BLUE}📦 Devcontainer Status:${NC}"
if [ -f ".devcontainer/devcontainer.json" ]; then
    echo -e "${GREEN}✅ Devcontainer configuration found${NC}"
    echo "   To test: Rebuild container via Command Palette"
    echo "   Command: 'Dev Containers: Rebuild Container'"
else
    echo -e "${RED}❌ No devcontainer configuration${NC}"
fi

echo ""
echo "==============================="
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "1. Save this output for comparison"
echo "2. Rebuild the devcontainer"
echo "3. Run this script again to verify SSH still works"
echo "4. If successful, we can add PostgreSQL and dependencies"
echo ""
