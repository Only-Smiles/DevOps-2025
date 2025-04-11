#!/usr/bin/env bash
source ~/.bash_profile

cd /minitwit || exit


# Deploy as a stack instead of compose
docker stack deploy -c stack.yml minitwit --with-registry-auth

# Update flagtool separately if needed
docker pull "$DOCKER_USERNAME"/flagtoolimage:latest