#! /usr/bin/env bash

docker run --rm -it \
--network minitwit_main \
--env PGPASSWORD=${DB_PWD} \
--volume ./src/minitwit/tmp/minitwit.db:/tmp/minitwit.db:ro \
--volume ./load.db:/tmp/load.db \
--platform linux/amd64 \
dimitri/pgloader bash -c "pgloader /tmp/load.db" \
&& export POSTGRES=yes \
&& docker compose -f dev-compose.yml up --build -d --force-recreate
