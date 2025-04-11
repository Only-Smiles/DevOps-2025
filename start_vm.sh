#!/usr/bin/env bash

sudo apt-get update

echo -e "\nOpening port for minitwit ...\n"
ufw allow 22/tcp
ufw allow 2376/tcp
ufw allow 4567/tcp
ufw allow 2377/tcp
ufw allow 7946/tcp
ufw allow 7946/udp
ufw allow 4789/udp
ufw reload
ufw --force enable

cd /minitwit || exit

# Load environment variables from .env file
set -o allexport
source .env.production
set +o allexport

# Overwrite ~/.bash_profile
echo "" > ~/.bash_profile

# Append variables to ~/.bash_profile
{
  echo ""
  echo "export DOCKER_USERNAME='$DOCKER_USERNAME'"
  echo "export DB_USER='$DB_USER'"
  echo "export DB_PWD='$DB_PWD'"
  echo "export GRAFANA_USERNAME='$GRAFANA_USERNAME'"
  echo "export GRAFANA_PASSWORD='$GRAFANA_PASSWORD'"
} > ~/.bash_profile

echo -e "\nConfiguring credentials as environment variables...\n"

source $HOME/.bash_profile

echo "\nInstalling jq for json parsing ...\n"
sudo apt-get install -y jq
wait -n
echo "\nInstalled jq for json parsing  ...\n"