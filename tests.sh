#!/usr/bin/env bash
set -eE -u -o pipefail

trap 'printf "\e[31m%s: %s\e[m\n" "Error!" $?' ERR

#functions
buildContainer() {
  docker compose down -v
  docker compose up --build -d
  while [[ 0 -eq $(docker compose logs | grep -c 'Container tag is') ]]; do
    docker compose logs | tail -5
    echo "!!!!!!!!! container is not ready !!!!!!!!!!!!!!!!"
    sleep 5
  done
}

checkDns() {
  dig +short www.free.fr @127.1.1.1 || true
  [[ $? -eq 0 ]] && echo "OK" || echo "KO"
}

checkAdmin() {
  res=$(curl -fs "http://0.0.0.0:8053/admin/login.php") || true
  [[ -n ${res} ]] && echo "http admin OK" || echo -e "\e[31mhttp admin KO \e[m\n"
  res=$(curl -fsk "https://0.0.0.0:1443/admin/login.php") || true
  [[ -n ${res} ]] && echo "https admin OK" || echo -e "\e[31mhttps admin KO \e[m"
}
#Main
buildContainer
checkDns
checkAdmin
docker compose stop
