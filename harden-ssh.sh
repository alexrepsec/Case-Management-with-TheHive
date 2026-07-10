#!/bin/bash
# =============================================================
# harden-ssh.sh — SSH Hardening Script
# Author: alexrepsec | github.com/alexrepsec
# Description: Applies SSH hardening as part of incident response
#              Task 3 — Operation Phantom Harvest
# =============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="$SSHD_CONFIG.bak"

echo -e "${YELLOW}"
echo "============================================"
echo "   SSH Hardening — Incident Response"
echo "   Operation Phantom Harvest"
echo "============================================"
echo -e "${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Run this script with sudo.${NC}"
    exit 1
fi

echo -e "${YELLOW}[*] Backing up sshd_config...${NC}"
cp "$SSHD_CONFIG" "$BACKUP"
echo -e "${GREEN}[+] Backup saved to $BACKUP${NC}"

echo -e "${YELLOW}[*] Disabling password authentication...${NC}"
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' "$SSHD_CONFIG"
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' "$SSHD_CONFIG"
echo -e "${GREEN}[+] PasswordAuthentication → no${NC}"

echo -e "${YELLOW}[*] Reducing MaxAuthTries to 3...${NC}"
sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' "$SSHD_CONFIG"
echo -e "${GREEN}[+] MaxAuthTries → 3${NC}"

echo -e "${YELLOW}[*] Disabling root login...${NC}"
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' "$SSHD_CONFIG"
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' "$SSHD_CONFIG"
echo -e "${GREEN}[+] PermitRootLogin → no${NC}"

echo -e "${YELLOW}[*] Verifying changes...${NC}"
echo ""
grep -E "PasswordAuthentication|MaxAuthTries|PermitRootLogin" "$SSHD_CONFIG" | grep -v "#"
echo ""

echo -e "${YELLOW}[*] Restarting SSH service...${NC}"
systemctl restart ssh
sleep 2
status=$(systemctl is-active ssh)
if [ "$status" == "active" ]; then
    echo -e "${GREEN}[+] SSH service restarted successfully — status: active${NC}"
else
    echo -e "${RED}[!] SSH service failed to restart — status: $status${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}[✓] SSH hardening complete.${NC}"
echo -e "${YELLOW}    Password-based brute force is no longer possible.${NC}"
