#!/bin/bash
# Note: fping have to be installed for using this script!

IP_LIST=(
    "192.168.1.1"
    "8.8.8.8"
)

INTERVAL=2
PING_TIMEOUT=200 #ms

RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
BOLD='\e[1m'
NC='\e[0m'

tput civis  # İmleç gizle

cleanup() {
    tput cnorm  # İmleci geri getir
    clear       # Terminali temizle
    exit
}

trap cleanup SIGINT

# Başlangıçta ekranı temizle ve imleci gizle
clear
echo -e " ${CYAN}PING MONITOR by Andasis Inc.${NC}\n"

# Başlık satırını yazdır
printf " ${BOLD}%-16s |  %-15s |  %-8s |  %s${NC}\n" "IP Address" "Result" "Latency" "Last Update"
echo -e "${BOLD}----------------------------------------------------------------${NC}"

# Her IP için bir satır ayır, boş satır yazdır
for ip in "${IP_LIST[@]}"; do
    printf " %-16s |  -               |  -        |  -\n" "$ip"
done

echo -e "\n${YELLOW}CTRL+C to exit.${NC}"
echo

while true; do
    # Her IP için ping at ve sonucu ilgili satıra yaz
	for i in "${!IP_LIST[@]}"; do
		ip=${IP_LIST[$i]}
		PING_OUTPUT=$(fping -c1 -t"$PING_TIMEOUT" "$ip" 2>&1)
		tput cup $((4 + i)) 0
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
