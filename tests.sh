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
	testip=$(grep -A1 ports docker-compose.yml | tail -1 | grep -oPm1 "(?<=- \")([0-9\.]+)")
  dig +short www.free.fr @${testip}
  [[ $? -eq 0 ]] && echo "DNS Resolution OK" || echo "DNS Resolution KO"
}

checkAdmin() {
	testip=$(grep -A1 ports docker-compose.yml | tail -1 | grep -oPm1 "(?<=- \")([0-9\.]+)")
  res=$(curl -fs "http://${testip}:8053/admin/login.php") || true
  [[ -n ${res} ]] && res=$(curl -fs "http://${testip}:8053/admin/login") || true
  [[ -n ${res} ]] && echo "http admin OK" || echo -e "\e[31mhttp admin KO \e[m\n"
  res=$(curl -fsk "https://${testip}:1443/admin/login.php") || true
  [[ -n ${res} ]] && res=$(curl -fs "https://${testip}:1443/admin/login") || true
  [[ -n ${res} ]] && echo "https admin OK" || echo -e "\e[31mhttps admin KO \e[m"
}
#Main
[[ ${1:-''} != "-t" ]] && buildContainer || true
checkDns
checkAdmin
[[ ${1:-''} != "-t" ]] && docker compose stop || true