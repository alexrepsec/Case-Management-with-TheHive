#!/bin/bash
# =============================================================
# deploy.sh — TheHive Lab Full Stack Deployment
# Author: alexrepsec | github.com/alexrepsec
# Description: Automates Docker deployment of TheHive + Cortex
# =============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LAB_DIR="$HOME/thehive-lab"

print_banner() {
echo -e "${YELLOW}"
cat << "EOF"
 _____ _          _   _ _
|_   _| |__   ___| | | (_)_   _____
  | | | '_ \ / _ \ |_| | \ \ / / _ \
  | | | | | |  __/  _  | |\ V /  __/
  |_| |_| |_|\___|_| |_|_| \_/ \___|

  Case Management Lab — Deployment Script
  Operation Phantom Harvest
EOF
echo -e "${NC}"
}

check_docker() {
    echo -e "${YELLOW}[*] Checking Docker...${NC}"
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}[!] Docker not found. Install Docker first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}[+] Docker found: $(docker --version)${NC}"
    echo -e "${GREEN}[+] Docker Compose: $(docker compose version)${NC}"
}

create_structure() {
    echo -e "${YELLOW}[*] Creating lab directory structure...${NC}"
    mkdir -p "$LAB_DIR"/{thehive,cortex,cassandra,elasticsearch,nginx}
    mkdir -p "$LAB_DIR"/cassandra/data
    mkdir -p "$LAB_DIR"/elasticsearch/data
    mkdir -p "$LAB_DIR"/thehive/data
    mkdir -p "$LAB_DIR"/thehive/logs
    mkdir -p "$LAB_DIR"/cortex/neurons
    echo -e "${GREEN}[+] Directory structure created at $LAB_DIR${NC}"
}

fix_permissions() {
    echo -e "${YELLOW}[*] Fixing permissions for Elasticsearch and TheHive...${NC}"
    sudo chown -R 1000:1000 "$LAB_DIR/elasticsearch/data"
    sudo chown -R 1000:1000 "$LAB_DIR/thehive/data"
    sudo chown -R 1000:1000 "$LAB_DIR/thehive/logs"
    echo -e "${GREEN}[+] Permissions set${NC}"
}

deploy_stack() {
    echo -e "${YELLOW}[*] Deploying TheHive stack with Docker Compose...${NC}"
    cd "$LAB_DIR"
    docker compose up -d
    echo -e "${GREEN}[+] Stack deployed${NC}"
}

wait_for_services() {
    echo -e "${YELLOW}[*] Waiting for services to initialize (60s)...${NC}"
    sleep 60
}

verify_deployment() {
    echo -e "${YELLOW}[*] Verifying containers...${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo -e "${GREEN}[+] TheHive  → http://localhost:9000${NC}"
    echo -e "${GREEN}[+] Cortex   → http://localhost:9001${NC}"
    echo ""
    echo -e "${YELLOW}Default credentials:${NC}"
    echo -e "  TheHive → admin@thehive.local / secret"
    echo -e "  Cortex  → admin / secret"
}

print_banner
check_docker
create_structure
fix_permissions
deploy_stack
wait_for_services
verify_deployment

echo -e "${GREEN}[✓] Deployment complete — Operation Phantom Harvest lab is ready.${NC}"
