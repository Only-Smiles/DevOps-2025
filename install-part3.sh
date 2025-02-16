#!/usr/bin/env bash

# Ensure all required arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <DIGITAL_OCEAN_TOKEN> <UNIQUE_HOSTNAME> <RESERVED_IP>"
    exit 1
fi

# Assign arguments to variables
DIGITAL_OCEAN_TOKEN="$1"
UNIQUE_HOSTNAME="$2"
RESERVED_IP="$3"

# Fetch the new droplet ID
NEW_DROPLET_ID=$(curl -s -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${DIGITAL_OCEAN_TOKEN}" \
    "https://api.digitalocean.com/v2/droplets?tag_name=webserver" | \
    jq -r --arg hostname "${UNIQUE_HOSTNAME}" '.droplets | map(select(.name == $hostname)) | .[0].id')

if [ -z "$NEW_DROPLET_ID" ]; then
    echo "Error: Could not find droplet with hostname '${UNIQUE_HOSTNAME}'"
    exit 1
fi

echo "New droplet ID: ${NEW_DROPLET_ID}"

# Reassign the reserved IP to the new droplet
echo "Reassigning reserved IP ${RESERVED_IP} to new droplet ${NEW_DROPLET_ID}..."
curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${DIGITAL_OCEAN_TOKEN}" \
    -d "{\"type\":\"assign\",\"droplet_id\": ${NEW_DROPLET_ID}}" \
    "https://api.digitalocean.com/v2/reserved_ips/${RESERVED_IP}/actions"

echo "Reserved IP reassigned."

# Wait for changes to propagate
sleep 5

# Find any old droplet with the same tag that is NOT the new droplet
OLD_DROPLET_ID=$(curl -s -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${DIGITAL_OCEAN_TOKEN}" \
    "https://api.digitalocean.com/v2/droplets?tag_name=webserver" | \
    jq -r --arg new_id "${NEW_DROPLET_ID}" '.droplets | map(select(.id != ($new_id | tonumber))) | .[0].id // empty')

# If an old droplet is found, terminate it
if [ -n "$OLD_DROPLET_ID" ]; then
    echo "Terminating old droplet with ID ${OLD_DROPLET_ID}..."
    curl -s -X DELETE \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${DIGITAL_OCEAN_TOKEN}" \
        "https://api.digitalocean.com/v2/droplets/${OLD_DROPLET_ID}"
    echo "Old droplet terminated."
else
    echo "No old droplet found to terminate."
fi
