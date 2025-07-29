#!/bin/bash

IP_LIST=(
    "192.168.103.1"
    "192.168.104.1"
    "192.168.105.1"
    "192.168.106.1"
    "192.168.107.1"
    "192.168.108.1"
    "192.168.109.1"
    "192.168.110.1"
    "192.168.111.1"
    "192.168.112.1"
    "192.168.113.1"
    "192.168.114.1"
    "192.168.115.1"
    "192.168.116.1"
    "192.168.117.1"
    "192.168.118.1"
    "192.168.3.1"
    "192.168.4.1"
    "192.168.5.1"
    "192.168.6.1"
    "192.168.7.1"
    "192.168.8.1"
    "192.168.9.1"
    "192.168.10.1"
    "192.168.11.1"
    "192.168.12.1"
    "192.168.13.1"
    "192.168.14.1"
    "192.168.15.1"
    "192.168.16.1"
    "192.168.17.1"
    "192.168.18.1"
    "192.168.1.1"
    "192.168.1.2"
    "192.168.30.1"
    "192.168.30.2"
)

tput civis  # İmleç gizle

cleanup() {
    tput cnorm  # İmleci geri getir
    clear       # Terminali temizle
    exit
}

trap cleanup SIGINT

# Başlangıçta ekranı temizle ve imleci gizle
clear
echo -e "PING MONITOR by Andasis Inc."
echo -e "General Time: $(date)\n--------------------------------------------------------------------------"

# Her IP için bir satır ayır, boş satır yazdır
for ip in "${IP_LIST[@]}"; do
    printf "%-15s -> ---\n" "$ip"
done

echo -e "\nCTRL+C to exit."
echo

while true; do
    # Zaman bilgisini güncelle
    tput cup 1 0
    echo -n "General Time: $(date)                     "

    # Her IP için ping at ve sonucu ilgili satıra yaz
	for i in "${!IP_LIST[@]}"; do
		ip=${IP_LIST[$i]}
		PING_OUTPUT=$(fping -c1 -t200 "$ip" 2>&1)
		tput cup $((3 + i)) 0
		CURRENT_TIME=$(date +"%H:%M:%S")

		if echo "$PING_OUTPUT" | grep -q "bytes"; then
		    PING_TIME=$(echo "$PING_OUTPUT" | sed -nE 's/.* ([0-9.]+) ms.*/\1/p')
		    printf "%-15s -> ✅ Response OK - Time: %5sms | Last Update: %s\n" "$ip" "$PING_TIME" "$CURRENT_TIME"
		else
		    printf "%-15s -> ❌ No Response                 | Last Update: %s\n" "$ip" "$CURRENT_TIME"
		fi
	done

    sleep 2
done
