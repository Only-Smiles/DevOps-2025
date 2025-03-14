source ~/.bash_profile

cd /minitwit

docker compose pull
docker compose up -d --remove-orphans
docker pull $DOCKER_USERNAME/flagtoolimage:latest

