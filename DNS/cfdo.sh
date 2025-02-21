#!/bin/bash

CF_API_TOKEN=""
CF_ZONE_ID=""
API_URL="https://api.cloudflare.com/client/v4"

HEADERS=(
    -H "Authorization: Bearer $CF_API_TOKEN"
    -H "Content-Type: application/json"
)

help() {
    echo "cfdo - Cloudflare DNS Operator"
    echo ""
    echo "Usage:"
    echo "  cfdo show-zone                                  		Show zone information"
    echo "  cfdo add-record <name> <content> [<type>]       		Add a new DNS record"
    echo "  cfdo update-record <record_id> [<type>] <name> <content>  	Update an existing DNS record"
    echo "  cfdo list-records [--full]                      		List all DNS records (use --full to show full content)"
    echo ""
    echo "Examples:"
    echo "  cfdo add-record A example.com 192.0.2.1"
    echo "  cfdo update-record <record_id> A example.com 192.0.2.3"


}

add_record() {
    local type=${3:-A}
    local name=$1
    local content=$2

    response=$(curl -s -X POST "${API_URL}/zones/${CF_ZONE_ID}/dns_records" \
        "${HEADERS[@]}" \
        --data '{
            "type": "'"$type"'",
            "name": "'"$name"'",
            "content": "'"$content"'",
            "ttl": 1,
            "proxied": false
        }')

    if [[ $(echo "$response" | jq -r '.success') == "true" ]]; then
        echo "Record added: $name ($type) -> $content"
    else
        echo "Failed to add record: $(echo "$response" | jq -r '.errors[].message')"
    fi
}

update_record() {
    local record_id=$1
    local type=${4:-A}
    local name=$2
    local content=$3

    response=$(curl -s -X PUT "${API_URL}/zones/${CF_ZONE_ID}/dns_records/${record_id}" \
        "${HEADERS[@]}" \
        --data '{
            "type": "'"$type"'",
            "name": "'"$name"'",
            "content": "'"$content"'",
            "ttl": 1,
            "proxied": false
        }')

    if [[ $(echo "$response" | jq -r '.success') == "true" ]]; then
        echo "Record updated: $name ($type) -> $content"
    else
        echo "Failed to update record: $(echo "$response" | jq -r '.errors[].message')"
    fi
}

show_zone() {
    response=$(curl -s -X GET "${API_URL}/zones/${CF_ZONE_ID}" "${HEADERS[@]}")

    if [[ $(echo "$response" | jq -r '.success') == "true" ]]; then
        echo "Zone Information:"
        echo "  Zone ID: $(echo "$response" | jq -r '.result.id')"
        echo "  Name: $(echo "$response" | jq -r '.result.name')"
        echo "  Status: $(echo "$response" | jq -r '.result.status')"
        echo "  Plan: $(echo "$response" | jq -r '.result.plan.name')"
    else
        echo "Failed to retrieve zone information: $(echo "$response" | jq -r '.errors[].message')"
    fi
}

if [[ "$#" -lt 1 ]]; then
    help
    exit 1
fi

command=$1
shift

list_records() {
    show_full_content=false
    if [[ "$1" == "--full" ]]; then
        show_full_content=true
    fi

    response=$(curl -s -X GET "${API_URL}/zones/${CF_ZONE_ID}/dns_records" "${HEADERS[@]}")

    if [[ $(echo "$response" | jq -r '.success') == "true" ]]; then
        printf "%-5s %-35s %-6s %-10s %-40s %-30s\n" "Rows" "ID" "Type" "Proxy" "Name" "Content"
        
        counter=1
        echo "$response" | jq -r '.result[] | "\(.id)\t\(.type)\t\(.proxied)\t\(.name)\t\(.content)"' | while IFS=$'\t' read -r id type proxied name content; do
            proxy_status=$( [ "$proxied" = "true" ] && echo "Proxied" || echo "DNS Only" )

            if [ "$show_full_content" = true ]; then
                display_content="$content"
            else
                display_content=$(echo "$content" | awk '{ if (length($0) > 27) printf "%.27s...", $0; else print $0 }')
            fi

            printf "%-5s %-35s %-6s %-10s %-40s %-30s\n" "$counter" "$id" "$type" "$proxy_status" "$name" "$display_content"
            ((counter++))
        done
    else
        echo "Failed to list records: $(echo "$response" | jq -r '.errors[].message')"
    fi
}

case "$command" in
    add-record)
        if [[ "$#" -lt 2 ]]; then
            echo "Error: Missing parameters for 'add-record' command."
            help
            exit 1
        fi
        add_record "$@"
        ;;
    list-records)
        list_records "$@"
        ;;
    update-record)
        if [[ "$#" -lt 3 ]]; then
            echo "Error: Missing parameters for 'update-record' command."
            help
            exit 1
        fi
        update_record "$@"
        ;;
    show-zone)
        show_zone
        ;;
    --help)
        help
        ;;
    *)
        echo "Error: Unknown command '$command'"
        help
        exit 1
        ;;
esac
