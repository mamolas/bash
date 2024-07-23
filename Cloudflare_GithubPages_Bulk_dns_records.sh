#!/bin/bash

# Cloudflare API token and Zone ID
API_TOKEN="*****"
ZONE_ID="****"

# Array of A records
A_RECORDS=(
    "185.199.108.153"
    "185.199.109.153"
    "185.199.110.153"
    "185.199.111.153"
)

# Array of AAAA records
AAAA_RECORDS=(
    "2606:50c0:8000::153"
    "2606:50c0:8001::153"
    "2606:50c0:8002::153"
    "2606:50c0:8003::153"
)

# Function to add DNS records
add_dns_record() {
    local record_type=$1
    local record_value=$2
    local name="@" # or your specific domain name if different

    curl -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json" \
        --data '{
            "type": "'"${record_type}"'",
            "name": "'"${name}"'",
            "content": "'"${record_value}"'",
            "ttl": 1,
            "proxied": true
        }'
}

# Add A records
for ip in "${A_RECORDS[@]}"; do
    add_dns_record "A" "$ip"
done

# Add AAAA records
for ip in "${AAAA_RECORDS[@]}"; do
    add_dns_record "AAAA" "$ip"
done
