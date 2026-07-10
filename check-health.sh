#!/bin/bash
# =============================================================
# check-health.sh — TheHive Lab Health Check
# Author: alexrepsec | github.com/alexrepsec
# Description: Verifies status of all lab containers and ports
# =============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

THEHIVE_URL="http://localhost:9000"
CORTEX_URL="http://localhost:9001"
ELASTIC_URL="http://localhost:9200"

check_container() {
    local name=$1
    local status
    status=$(docker inspect --format='{{.State.Status}}' "$name" 2>/dev/null)
    if [ "$status" == "running" ]; then
        echo -e "  ${GREEN}[+] $name → running${NC}"
    else
        echo -e "  ${RED}[!] $name → $status${NC}"
    fi
}

check_port() {
    local service=$1
    local url=$2
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null)
    if [ "$code" == "200" ] || [ "$code" == "302" ] || [ "$code" == "301" ]; then
        echo -e "  ${GREEN}[+] $service → HTTP $code — reachable${NC}"
    else
        echo -e "  ${RED}[!] $service → HTTP $code — unreachable${NC}"
    fi
}

echo -e "${YELLOW}"
echo "============================================"
echo "   TheHive Lab — Health Check"
echo "============================================"
echo -e "${NC}"

echo -e "${YELLOW}[*] Container Status:${NC}"
check_container "thehive"
check_container "cortex"
check_container "cassandra"
check_container "elasticsearch"

echo ""
echo -e "${YELLOW}[*] Service Reachability:${NC}"
check_port "TheHive  (9000)" "$THEHIVE_URL"
check_port "Cortex   (9001)" "$CORTEX_URL"
check_port "Elastic  (9200)" "$ELASTIC_URL"

echo ""
echo -e "${YELLOW}[*] Firewall Status:${NC}"
sudo ufw status | grep -E "Status|DENY|ALLOW"

echo ""
echo -e "${YELLOW}[*] SSH Service:${NC}"
systemctl is-active ssh && echo -e "  ${GREEN}[+] SSH → active${NC}" || echo -e "  ${RED}[!] SSH → inactive${NC}"

echo ""
echo -e "${YELLOW}[*] PasswordAuthentication:${NC}"
result=$(sudo grep "PasswordAuthentication" /etc/ssh/sshd_config | grep -v "#")
echo -e "  ${GREEN}$result${NC}"

echo ""
echo -e "${GREEN}[✓] Health check complete.${NC}"
