#!/usr/bin/env bash

# Ensure all required arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <DIGITAL_OCEAN_TOKEN> <UNIQUE_HOSTNAME> <RESERVED_IP> <SSH_KEYS>"
    exit 1
fi

# Assign arguments to variables
DIGITAL_OCEAN_TOKEN="$1"
UNIQUE_HOSTNAME="$2"
RESERVED_IP="$3"
SSH_KEYS="$4"

echo "Using SSH Keys: $[SSH_KEYS]"

# Fetch the new droplet ID
SWARM_MANAGER_ID=$(curl -s -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${DIGITAL_OCEAN_TOKEN}" \
    "https://api.digitalocean.com/v2/droplets?tag_name=webserver" | \
    jq -r --arg hostname "${UNIQUE_HOSTNAME}" '.droplets | map(select(.name == $hostname)) | .[0].id')

if [ -z "$SWARM_MANAGER_ID" ]; then
    echo "Error: Could not find droplet with hostname '${UNIQUE_HOSTNAME}'"
    exit 1
fi

WORKER1_ID=$(curl -X POST "$DROPLETS_API"\
       -d "{\"name\":\"worker1\",\"tags\":[\"worker\"],\"region\":\"fra1\",
       \"size\":\"s-1vcpu-1gb\",\"image\":\"docker-20-04\",
       \"ssh_keys\":[${SSH_KEYS}]}" \
       -H "$BEARER_AUTH_TOKEN" -H "$JSON_CONTENT"\
       | jq -r .droplet.id )\
       && sleep 3 && echo $WORKER1_ID