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

# Initialize Counters and Timestamps
declare -A success_count fail_count last_success_time last_fail_time

# Terminal setup
tput reset
tput civis  # Hide cursor

cleanup() {
    tput cnorm  # Bring back the cursor
    clear       # Clear terminal
    exit
}

trap cleanup SIGINT

# Print Static Headers
echo -e " ${CYAN}PING MONITOR by Andasis Inc.\n${NC}"
printf " ${BOLD}%-15s  |  %-14s  |  %-7s  |  %-15s  |  %-9s  |  %-6s  |  %-7s  |  %-4s  |  %-8s  |  %s${NC}\n" \
       "Target IP" "Result" "Latency" "Source IP" "Interface" "Success" "Failure" "Rate" "Last Change" "Last Update"
echo -e "${BOLD}---------------------------------------------------------------------------------------------------------------------------------------------------${NC}"

# Initial Placeholder Rows
for ip in "${IP_LIST[@]}"; do
    success_count["$ip"]=0
    fail_count["$ip"]=0
    last_success_time["$ip"]="-"
    last_fail_time["$ip"]="-"
    printf " %-15s  |  -               |  -        |  -                |  -          |  0        |  0        |  %%0    |  -            |  -\n" "$ip"
done

echo -e "\n${BOLD}CTRL+C to exit.${NC}"

# Main Loop
while true; do
    for i in "${!IP_LIST[@]}"; do
        ip=${IP_LIST[$i]}
        route_info=$(ip route get "$ip" 2>/dev/null)

        src_ip=$(echo "$route_info" | awk '{for (i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')
        iface=$(echo "$route_info" | awk '{for (i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}')

        PING_OUTPUT=$(fping -c1 -t"$PING_TIMEOUT" "$ip" 2>&1)
        CURRENT_TIME=$(date +"%H:%M:%S")
        tput cup $((4 + i)) 0

        if echo "$PING_OUTPUT" | grep -q "bytes"; then
            PING_TIME=$(echo "$PING_OUTPUT" | sed -nE 's/.* ([0-9.]+) ms.*/\1/p')
            ((success_count["$ip"]++))
            last_success_time["$ip"]="$CURRENT_TIME"
            last_change_time="${last_fail_time["$ip"]}"
        else
            PING_TIME="-"
            ((fail_count["$ip"]++))
            last_fail_time["$ip"]="$CURRENT_TIME"
            last_change_time="${last_success_time["$ip"]}"
        fi

        total=$(( success_count["$ip"] + fail_count["$ip"] ))
        if (( total > 0 )); then
            rate=$(( 100 * success_count["$ip"] / total ))
        else
            rate=0
        fi

        if [[ "$PING_TIME" != "-" ]]; then
            printf " ${GREEN}%-15s${NC}  |  ✅ ${GREEN}Successfull${NC}  |  %-5sms  |  %-16s |  %-10s |  %-7s  |  %-7s  |  %%%-3s  |  %-11s  |  %s\n" \
                "$ip" "$PING_TIME" "$src_ip" "$iface" "${success_count["$ip"]}" "${fail_count["$ip"]}" "$rate" "$last_change_time" "$CURRENT_TIME"
        else
            printf " ${RED}%-15s${NC}  |  ❌ ${RED}No Response${NC}  |  -        |  %-16s |  %-10s |  %-7s  |  %-7s  |  %%%-3s  |  %-11s  |  %s\n" \
                "$ip" "$src_ip" "$iface" "${success_count["$ip"]}" "${fail_count["$ip"]}" "$rate" "$last_change_time" "$CURRENT_TIME"
        fi
    done

    sleep "$INTERVAL"
done
