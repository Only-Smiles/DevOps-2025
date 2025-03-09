#! /usr/bin/env bash

docker run --rm -it \
--network minitwit_main \
--env PGPASSWORD=${DB_PWD} \
--volume /tmp/minitwit.db:/tmp/minitwit.db:ro \
--volume ./load.db:/tmp/load.db \
--platform linux/amd64 \
dimitri/pgloader bash -c "pgloader /tmp/load.db" \
&& export POSTGRES=yes \
&& docker compose up -d --force-recreate
