#!/bin/bash

# Check if fping is installed
if ! command -v fping >/dev/null 2>&1; then
    echo "Error: fping is not installed. Please install it with:"
    echo "  sudo apt-get install fping"
    exit 1
fi

# Show usage/help message
show_usage() {
    echo ""
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Periodically pings a list of IP addresses and updates results in-place."
    echo ""
    echo "Options:"
    echo "  -i, --interval N        Set interval between ping rounds (default: $INTERVAL seconds)"
    echo "  -t, --timeout  N        Set timeout for each ping (default: $PING_TIMEOUT ms)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "To change the IP list, edit the script and modify the IP_LIST array:"
    echo "  IP_LIST=("
    echo "    \"192.168.1.1\""
    echo "    \"8.8.8.8\""
    echo "    ...etc"
    echo "  )"
    echo ""
    echo "Example:"
    echo "  ./$(basename "$0") -i 5 -t 300"
    echo ""
    exit 0
}

IP_LIST=(
    "192.168.1.1"
    "8.8.8.8"
)

INTERVAL=2
PING_TIMEOUT=200 #ms

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -t|--timeout)
            PING_TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
MAGENTA='\e[1;35m'
BOLD='\e[1m'
NC='\e[0m'

tput civis  # Hide cursor

cleanup() {
    tput cnorm  # Bring back the cursor
    clear       # Clear terminal
    exit
}

trap cleanup SIGINT

# Clear the terminal and hide the cursor at the beginning
clear
echo -e " ${CYAN}PING MONITOR by Andasis Inc.${NC}"
SOURCE_IP=$(ip route get 8.8.8.8 | awk '/src/ {print $7}')
echo -e " ${MAGENTA}Source IP found as: $SOURCE_IP\n${NC}"

# Başlık satırını yazdır
printf " ${BOLD}%-16s |  %-15s |  %-8s |  %s${NC}\n" "IP Address" "Result" "Latency" "Last Update"
echo -e "${BOLD}----------------------------------------------------------------${NC}"

# Allocate one line for each IP, print blank lines
for ip in "${IP_LIST[@]}"; do
    printf " %-16s |  -               |  -        |  -\n" "$ip"
done

echo -e "\n${BOLD}CTRL+C to exit.${NC}"
echo

while true; do
    # Ping each IP and write the result to the relevant line
	for i in "${!IP_LIST[@]}"; do
		ip=${IP_LIST[$i]}
		PING_OUTPUT=$(fping -c1 -t"$PING_TIMEOUT" "$ip" 2>&1)
		tput cup $((5 + i)) 0
		CURRENT_TIME=$(date +"%H:%M:%S")

		if echo "$PING_OUTPUT" | grep -q "bytes"; then
		    PING_TIME=$(echo "$PING_OUTPUT" | sed -nE 's/.* ([0-9.]+) ms.*/\1/p')
		    printf " ${GREEN}%-16s${NC} |  ✅ ${GREEN}Response OK${NC}  | %5sms   |  %s\n" "$ip" "$PING_TIME" "$CURRENT_TIME"
		else
		    printf " ${RED}%-16s${NC} |  ❌ ${RED}No Response${NC}  |  -        |  %s\n" "$ip" "$CURRENT_TIME"
		fi
	done

    sleep "$INTERVAL"
done
