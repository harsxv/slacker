#!/bin/bash

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLINK='\033[5m'
NC='\033[0m' # No Color

# Function to connect to WHM via SSH
connect_to_whm() {
    local hostname=$1
    echo -e "${RED}== ${CYAN}Connecting to WHM on ${GREEN}$hostname${NC}..."
    ssh -t $hostname "sudo whmlogin"
}

# Function to execute sudo on the remote server
execute_sudo() {
    local hostname=$1
    echo -e "${RED}== ${CYAN}Executing sudo on ${GREEN}$hostname${NC}..."
    ssh -t $hostname "sudo -i"
}

# Help function
help_function() {
    echo -e "${RED}usage: -o <whm|sudo> <domain>${NC}"
    exit 1
}

# Check if a domain is provided as an argument
if [ $# -eq 0 ]; then
    help_function
fi

# Execute the appropriate action based on the provided option
case "$connect_option" in
    "whm")
        connect_to_whm $hostname
        ;;
    "sudo")
        execute_sudo $hostname
        ;;
    *)
        help_function
        ;;
esac

echo -e "${CYAN}Checking server status.. ${NC}"

# Check for the -o option
if [ "$1" == "-o" ]; then
    shift  # Remove the -o option from the argument list
    connect_option=$1
    shift  # Remove the connect option from the argument list
else
    help_function
fi

domain=$1

# Get the IP address of the domain
ip_address=$(dig +short $domain)

# Check if the domain has an IP address
if [ -z "$ip_address" ]; then
    echo -e "${RED}Domain '$domain' does not have an IP address.${NC}"
    exit 1
fi

echo -e "${RED}== ${CYAN}$domain is pointing to ${GREEN}$ip_address${NC}"

# Get the A record (hostname) of the IP address and remove the trailing dot
hostname=$(dig +short -x "$ip_address" | sed 's/\.$//')

# Check if the A record is available
if [ -z "$hostname" ]; then
    echo -e "${YELLOW}No A record (hostname) found for IP address: $ip_address${NC}"
    exit 1
fi

echo -e "${RED}== ${CYAN}IP ${GREEN}$ip_address ${NC}: ${GREEN}$hostname${NC}"


