#!/bin/bash
# Check if IP addresses in a given range are listed on UCEPROTECT blacklists

if [ -z "$1" ]; then
    echo "Usage: $0 <IP-Range (e.g., 192.168.0.{1..254})>"
    exit 1
fi

IP_RANGE=$1

BLISTS="
dnsbl-1.uceprotect.net
"

reverse_ip() {
    local ip=$1
    local -a ip_parts
    IFS='.' read -r -a ip_parts <<< "$ip"
    echo "${ip_parts[3]}.${ip_parts[2]}.${ip_parts[1]}.${ip_parts[0]}"
}

for ip in $(eval echo $IP_RANGE); do
    reverse=$(reverse_ip $ip)

    if [ -z "$reverse" ]; then
        echo "Error: '$ip' doesn't look like a valid IP address"
        exit 1
    fi

    # Check the UCEPROTECT blacklists
    for BL in ${BLISTS}; do
        reversed_ip="${reverse}.${BL}"

        dig +short -t a $reversed_ip > /tmp/rbl$ip.txt
        cekrbl=$(cat /tmp/rbl$ip.txt)

	if [ -z "$cekrbl" ]; then
		printf "%-15s %-30s 🟢 NOT LISTED\n" "$ip" "$BL"
	else
		printf "%-15s %-30s 🔴 LISTED\n" "$ip" "$BL"
	fi
    done
done
