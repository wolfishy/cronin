#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Update the system
sudo apt update >/dev/null 2>&1

# Install supervisor
sudo apt install -y supervisor >/dev/null 2>&1

# DevContainer Welcome Script
echo -e "${CYAN}╭───────────────────────────────╮${NC}"
echo -e "${CYAN}│${WHITE}        Nexus Node Setup       ${CYAN}│${NC}"
echo -e "${CYAN}╰┬──────────────────────────────╯${NC}"
echo -e " ${CYAN}│${NC}"
echo -e -n " ${CYAN}└${NC} ${YELLOW}What's node id? ${NC}"
read ID
echo -e "\033[1A\033[K ${CYAN}├${NC} ${YELLOW}What's node id? ${NC}${CYAN}$ID${NC}"
echo -e -n " ${CYAN}└${NC} ${YELLOW}What's supervisor username? ${NC}"
read SUPERVISOR_USERNAME
echo -e "\033[1A\033[K ${CYAN}├${NC} ${YELLOW}What's supervisor username? ${NC}${CYAN}$SUPERVISOR_USERNAME${NC}"
echo -e -n " ${CYAN}└${NC} ${YELLOW}What's supervisor password? ${NC}"
read -s SUPERVISOR_PASSWORD
echo -e "\033[1A\033[K ${CYAN}└${NC} ${YELLOW}What's supervisor password? ${NC}${RED}[hidden]${NC}"
echo ""

# Export the variables so they're available in the shell session
export ID SUPERVISOR_USERNAME SUPERVISOR_PASSWORD

# Create the whaleon.conf file
sudo tee /etc/supervisor/conf.d/whaleon.conf > /dev/null <<EOF
[program:whaleon-$ID]
user=root
command=nice -n -15 /workspaces/cronin/whaleon start --headless --max-threads 4 --node-id $ID
directory=/workspaces/cronin
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/whaleon.err.log
stdout_logfile=/var/log/supervisor/whaleon.out.log

[inet_http_server]
port=0.0.0.0:9876
username=$SUPERVISOR_USERNAME
password=$SUPERVISOR_PASSWORD
EOF

echo ""
echo -e "${BLUE}Starting supervisor configuration...${NC}"
sudo supervisord -c /etc/supervisor/supervisord.conf

echo ""
echo -e "${GREEN}╭─ ✓ You're all set! ${NC}"
echo -e "${GREEN}│${NC}"
echo -e "${GREEN}│${WHITE} Node ID: ${CYAN}$ID${NC}"
echo -e "${GREEN}│${WHITE} Dashboard: ${CYAN}http://localhost:9876${NC}"
echo -e "${GREEN}│${WHITE} Username: ${CYAN}$SUPERVISOR_USERNAME${NC}"
echo -e "${GREEN}│${WHITE} Password: ${RED}[hidden]${NC}"
echo -e "${GREEN}╰───────────────────${NC}"
