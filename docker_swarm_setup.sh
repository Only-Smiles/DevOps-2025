#!/usr/bin/env bash
# shellcheck disable=SC2029

# Ensure all required arguments are provided
eval "$(ssh-agent -s)"
ssh-add "/Users/lauritsbrok/.ssh/id_ed25519"

# Assign arguments to variables
JSON_CONTENT="Content-Type: application/json"
BEARER_AUTH_TOKEN="Authorization: Bearer $DIGITAL_OCEAN_TOKEN"
DROPLETS_API="https://api.digitalocean.com/v2/droplets"

# Function to fetch all ssh keys registered in Digital Ocean
fetch_digitalocean_ssh_key_ids() {
  local response body code
  response=$(curl -s -w "\n%{http_code}" -H "$BEARER_AUTH_TOKEN" \
    "https://api.digitalocean.com/v2/account/keys")

  body=$(echo "$response" | sed '$d')
  code=$(echo "$response" | tail -n1)

  if [ "$code" == "200" ]; then
    echo "$body" | jq '[.ssh_keys[].id]'
  else
    echo "Failed to fetch SSH keys: $body" >&2
    exit 1
  fi
}

# Function to create a droplet
create_droplet() {
    local droplet_name=$1
    local droplet_tag=$2
    local response
    response=$(curl -s -X POST "$DROPLETS_API" \
       -d "{
             \"name\":\"${droplet_name}\",
             \"tags\":[\"${droplet_tag}\"],
             \"region\":\"fra1\",
             \"size\":\"s-1vcpu-2gb\",
             \"image\":\"docker-20-04\",
             \"ssh_keys\":$SSH_KEYS
           }" \
       -H "$BEARER_AUTH_TOKEN" \
       -H "$JSON_CONTENT")
    echo "$response" | jq -r .droplet.id
}

# Function to poll for a public IPv4 address
poll_for_ip() {
    local droplet_id=$1
    local ip_address=""
    echo "Waiting for public IPv4 address for droplet ID: $droplet_id..." >&2
    while true; do
        ip_address=$(curl -s -X GET \
            -H "$BEARER_AUTH_TOKEN" \
            -H "$JSON_CONTENT" \
            "$DROPLETS_API/$droplet_id" \
            | jq -r '.droplet.networks.v4[] | select(.type == "public") | .ip_address')

        if [[ -n "$ip_address" ]]; then
            echo "$ip_address"
            break
        fi

        echo "No public IPv4 address yet for droplet ID: $droplet_id. Waiting 30 seconds..." >&2
        sleep 30
    done
}

get_or_create_reserved_ip() {
  # Make a GET request to fetch existing reserved IPs
  response=$(curl -s -X GET "https://api.digitalocean.com/v2/reserved_ips" \
    -H "Authorization: Bearer $DIGITAL_OCEAN_TOKEN" \
    -H "Content-Type: application/json")

  # Look for a reserved IP matching the specified region
  reserved_ip=$(echo "$response" | jq -r --arg region "$DROPLET_REGION" \
    '.reserved_ips[]? | select(.region.slug == $region) | .ip' | head -n 1)

  if [ -n "$reserved_ip" ]; then
    echo "Using existing reserved IP: $reserved_ip"
    echo "$reserved_ip"
  else
    echo "Requesting a new reserved IP..."
    # Create a new reserved IP for the region using a POST request
    create_response=$(curl -s -X POST "https://api.digitalocean.com/v2/reserved_ips" \
      -H "Authorization: Bearer $DIGITAL_OCEAN_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"region\": \"$DROPLET_REGION\"}")

    new_reserved_ip=$(echo "$create_response" | jq -r '.reserved_ip.ip')
    echo "New reserved IP created: $new_reserved_ip"
    echo "$new_reserved_ip"
  fi
}

SSH_KEYS=$(fetch_digitalocean_ssh_key_ids)
SWARM_MANAGER_NAME="SwarmManager-202504062013"

echo "Using SSH Keys: $SSH_KEYS"

if [ -z "$DIGITAL_OCEAN_TOKEN" ]; then
    echo "Error: DIGITAL_OCEAN_TOKEN is not set"
    exit 1
fi

# Create worker nodes
MANAGER_ID=$(create_droplet $SWARM_MANAGER_NAME "manager")
echo "Created manager droplet with ID: $MANAGER_ID"

# Create worker nodes
WORKER1_ID=$(create_droplet "worker1" "worker")
echo "Created worker1 droplet with ID: $WORKER1_ID"

WORKER2_ID=$(create_droplet "worker2" "worker")
echo "Created worker2 droplet with ID: $WORKER2_ID"

# Get worker IPs
IPV4_SWARM_MANAGER=$(poll_for_ip "$MANAGER_ID")
echo "Found public IPv4 address for manager: $IPV4_SWARM_MANAGER"

# Get worker IPs
IPV4_WORKER1=$(poll_for_ip "$WORKER1_ID")
echo "Found public IPv4 address for worker1: $IPV4_WORKER1"

IPV4_WORKER2=$(poll_for_ip "$WORKER2_ID")
echo "Found public IPv4 address for worker2: $IPV4_WORKER2"

sleep 45

scp -o StrictHostKeyChecking=no -r remote_files root@"$IPV4_WORKER1":/minitwit
scp -o StrictHostKeyChecking=no -r remote_files root@"$IPV4_WORKER2":/minitwit
scp -o StrictHostKeyChecking=no -r remote_files root@"$IPV4_SWARM_MANAGER":/minitwit

ssh -o StrictHostKeyChecking=no root@"$IPV4_SWARM_MANAGER" 'bash -s' < ./start_vm.sh
ssh -o StrictHostKeyChecking=no root@"$IPV4_WORKER1" 'bash -s' < ./start_vm.sh
ssh -o StrictHostKeyChecking=no root@"$IPV4_WORKER2" 'bash -s' < ./start_vm.sh

# Initialize swarm
ssh root@"$IPV4_SWARM_MANAGER" "docker swarm init --advertise-addr=$IPV4_SWARM_MANAGER"

# Output the join token for workers
WORKER_TOKEN=$(ssh root@"$IPV4_SWARM_MANAGER" "docker swarm join-token worker -q")

echo "Worker token: $WORKER_TOKEN"

# shellcheck disable=SC2029
ssh root@"$IPV4_WORKER1" "docker swarm join --token ${WORKER_TOKEN} $IPV4_SWARM_MANAGER:2377"
# shellcheck disable=SC2029
ssh root@"$IPV4_WORKER2" "docker swarm join --token ${WORKER_TOKEN} $IPV4_SWARM_MANAGER:2377"

chmod +x reassign_reserved_ip.sh
./reassign_reserved_ip.sh $SWARM_MANAGER_NAME "$(get_or_create_reserved_ip)"