#!/usr/bin/env bash
set -ex

docker compose down -v
docker compose up --build -d

while [[ 0 -eq $(docker compose logs | grep -c 'Container tag is') ]]
do
  docker compose logs| tail -5
  echo "!!!!!!!!! container is not ready !!!!!!!!!!!!!!!!"
  sleep 5
done

dig www.free.fr @127.1.1.1
[[ $? -eq 0 ]] && echo "OK" || echo "KO"
docker compose stop