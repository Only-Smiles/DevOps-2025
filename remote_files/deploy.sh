source ~/.bash_profile

cd /minitwit

docker compose -f compose.yml pull
docker compose -f compose.yml up -d
docker pull $DOCKER_USERNAME/flagtoolimage:latest