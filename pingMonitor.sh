#!/bin/bash

# Check if fping is installed
if ! command -v fping >/dev/null 2>&1; then
    echo "Error: fping is not installed. Please install it with:"
    echo "  sudo apt-get install fping"
    exit 1
fi

INTERVAL=2
PING_TIMEOUT=200 #ms
OPEN_MENU=false

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
        -m|--manage)
            OPEN_MENU=true
            shift
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

# Show usage/help message
show_usage() {
    echo ""
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Periodically pings a list of IP addresses and updates results in-place."
    echo ""
    echo "Options:"
    echo "  -i, --interval N        Set interval between ping rounds (default: 2 seconds)"
    echo "  -t, --timeout  N        Set timeout for each ping (default: 200 ms)"
    echo "  -m, --manage            Open IP management menu immediately"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Keyboard Controls:"
    echo "  CTRL+O                  Open IP management menu during monitoring"
    echo "  CTRL+C                  Exit program"
    echo ""
    echo "IP addresses are stored in: $CONFIG_FILE"
    echo ""
    exit 0
}

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
MAGENTA='\e[1;35m'
BOLD='\e[1m'
NC='\e[0m'

# Configuration file path
CONFIG_FILE="${HOME}/.ping_monitor_ips.conf"

# Load IP addresses from config file
load_ips() {
    if [[ -f "$CONFIG_FILE" ]]; then
        mapfile -t IP_LIST < "$CONFIG_FILE"
        # Remove empty lines
        IP_LIST=("${IP_LIST[@]//[[:space:]]/}")
        IP_LIST=("${IP_LIST[@]/#/}")
        local temp=()
        for ip in "${IP_LIST[@]}"; do
            [[ -n "$ip" ]] && temp+=("$ip")
        done
        IP_LIST=("${temp[@]}")
    fi
    
    # If no IPs loaded, use defaults
    if [[ ${#IP_LIST[@]} -eq 0 ]]; then
        IP_LIST=(
            "192.168.1.1"
            "8.8.8.8"
        )
        save_ips
    fi
}

# Save IP addresses to config file
save_ips() {
    printf "%s\n" "${IP_LIST[@]}" > "$CONFIG_FILE"
}

# IP Management Menu
manage_ips() {
    tput cnorm  # Show cursor
    clear
    
    while true; do
        echo -e "${BOLD}${CYAN}════════════════════════════════════════${NC}"
        echo -e "${BOLD}${CYAN}       IP ADDRESS MANAGEMENT MENU${NC}"
        echo -e "${BOLD}${CYAN}════════════════════════════════════════${NC}"
        echo ""
        echo -e "${BOLD}Current IP Addresses:${NC}"
        echo -e "${BOLD}────────────────────────────────────────${NC}"
        
        if [[ ${#IP_LIST[@]} -eq 0 ]]; then
            echo "  (No IP addresses configured)"
        else
            for i in "${!IP_LIST[@]}"; do
                printf "  %2d. %s\n" $((i+1)) "${IP_LIST[$i]}"
            done
        fi
        
        echo -e "${BOLD}────────────────────────────────────────${NC}"
        echo -e "${BOLD}Options:${NC}"
        echo -e "${BOLD}${MAGENTA}  [A] Add new IP address${NC}"
        echo -e "${BOLD}${MAGENTA}  [G] Add new IP address range${NC}"
        echo -e "${BOLD}${MAGENTA}  [D] Delete IP address${NC}"
        echo -e "${BOLD}${MAGENTA}  [C] Clear all IP addresses${NC}"
        echo -e "${BOLD}${MAGENTA}  [R] Return to monitoring${NC}"
        echo -e "${BOLD}${MAGENTA}  [Q] Quit program${NC}"
        echo -e "${BOLD}────────────────────────────────────────${NC}"
        echo -n "Select option: "
        
        read -r choice
        choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')
        
        case "$choice" in
            A)
                echo -n "Enter IP address to add: "
                read -r new_ip
                if [[ -n "$new_ip" ]]; then
                    # Basic IP validation
                    if [[ "$new_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                        # Check for duplicate
                        duplicate=false
                        for existing_ip in "${IP_LIST[@]}"; do
                            if [[ "$existing_ip" == "$new_ip" ]]; then
                                duplicate=true
                                break
                            fi
                        done
                        
                        if [[ "$duplicate" == true ]]; then
                            echo -e "${RED}✗ IP address already exists in the list${NC}"
                            sleep 3
                        else
                            IP_LIST+=("$new_ip")
                            save_ips
                            echo -e "${GREEN}✓ Added: $new_ip${NC}"
                            sleep 2
                        fi
                    else
                        echo -e "${RED}✗ Invalid IP address format${NC}"
                        sleep 2
                    fi
                fi
                ;;
            G)
                echo -n "Enter IP range (e.g., 192.168.5.1-5): "
                read -r range_input
                if [[ -n "$range_input" ]]; then
                    # Parse range format: xxx.xxx.xxx.start-end
                    if [[ "$range_input" =~ ^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)([0-9]{1,3})-([0-9]{1,3})$ ]]; then
                        base_ip="${BASH_REMATCH[1]}"
                        start_octet="${BASH_REMATCH[2]}"
                        end_octet="${BASH_REMATCH[3]}"
                        
                        # Validate range
                        if [[ $start_octet -gt 255 ]] || [[ $end_octet -gt 255 ]]; then
                            echo -e "${RED}✗ IP octets must be between 0 and 255${NC}"
                            sleep 3
                        elif [[ $start_octet -gt $end_octet ]]; then
                            echo -e "${RED}✗ Start value must be less than or equal to end value${NC}"
                            sleep 3
                        else
                            added_count=0
                            skipped_count=0
                            
                            for ((octet=start_octet; octet<=end_octet; octet++)); do
                                new_ip="${base_ip}${octet}"
                                
                                # Check for duplicate
                                duplicate=false
                                for existing_ip in "${IP_LIST[@]}"; do
                                    if [[ "$existing_ip" == "$new_ip" ]]; then
                                        duplicate=true
                                        ((skipped_count++))
                                        break
                                    fi
                                done
                                
                                if [[ "$duplicate" == false ]]; then
                                    IP_LIST+=("$new_ip")
                                    ((added_count++))
                                fi
                            done
                            
                            save_ips
                            echo -e "${GREEN}✓ Added $added_count IP(s)${NC}"
                            if [[ $skipped_count -gt 0 ]]; then
                                echo "  Skipped $skipped_count duplicate(s)"
                            fi
                            sleep 3
                        fi
                    else
                        echo -e "${RED}✗ Invalid range format. Use: 192.168.5.1-5${NC}"
                        sleep 3
                    fi
                fi
                ;;
            D)
                if [[ ${#IP_LIST[@]} -eq 0 ]]; then
                    echo -e "${RED}✗ No IP addresses to delete${NC}"
                    sleep 2
                else
                    echo -n "Enter number to delete (1-${#IP_LIST[@]}): "
                    read -r num
                    if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#IP_LIST[@]} ]]; then
                        deleted_ip="${IP_LIST[$((num-1))]}"
                        unset 'IP_LIST[$((num-1))]'
                        IP_LIST=("${IP_LIST[@]}")  # Re-index array
                        save_ips
                        echo -e "${GREEN}✓ Deleted: $deleted_ip${NC}"
                        sleep 2
                    else
                        echo -e "${RED}✗ Invalid selection${NC}"
                        sleep 2
                    fi
                fi
                ;;
            C)
                echo -n "Clear all IP addresses? (y/N): "
                read -r confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    IP_LIST=()
                    save_ips
                    echo -e "${GREEN}✓ All IP addresses cleared${NC}"
                    sleep 2
                fi
                ;;
            R)
                if [[ ${#IP_LIST[@]} -eq 0 ]]; then
                    echo -e "${RED}✗ Cannot monitor with no IP addresses! Add at least one IP!${NC}"
                    sleep 3
                else
                    clear
                    return 0
                fi
                ;;
            Q)
                clear
                exit 0
                ;;
            *)
                echo -e "${RED}✗ Invalid option!${NC}"
                sleep 2
                ;;
        esac
        clear
    done
}

# Load IPs from config file
load_ips

# Open menu if requested
if [[ "$OPEN_MENU" == true ]]; then
    manage_ips
fi

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

# Function to check for CTRL+O (ASCII 15)
check_menu_trigger() {
    # Read with timeout to not block
    if read -t 0.01 -n 1 key 2>/dev/null; then
        if [[ $(printf '%d' "'$key") -eq 15 ]]; then
            manage_ips
            # Reinitialize after menu
            tput reset
            tput civis
            print_monitor_interface
        fi
    fi
}

print_monitor_interface() {
    echo -e " ${CYAN}PING MONITOR by Andasis Inc.${NC}\n"
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
    
    echo -e "\n${BOLD}CTRL+C to exit  |  ${MAGENTA}CTRL+O to manage IPs${NC}"
}

# Print initial interface
print_monitor_interface

# Main Loop
while true; do
    check_menu_trigger
    
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
