#!/usr/bin/env bash
set -eE -u -o pipefail

trap 'printf "\e[31m%s: %s\e[m\n" "Error!" $?' ERR
#set -x
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

BR=$(git status | grep -oP "(?<=Sur la branche ).*" | grep -c "development" || true)
if [[ 0 -eq ${BR} ]]; then
  CPSE=compose.yml
else
  CPSE=compose-dev.yml
fi

#functions
buildContainer() {
  docker compose down -v
  docker compose up --build -d
  while [[ 0 -eq $(docker compose -f ${CPSE} logs | grep -cP '(Container tag is|INFO: Blocking status is enabled)') ]]; do
    docker compose -f ${CPSE} logs | tail -5
    echo "!!!!!!!!! container is not ready !!!!!!!!!!!!!!!!"
    sleep 5
  done
}

checkDns() {
	testip=$(grep -A1 ports ${CPSE} | tail -1 | grep -oPm1 "(?<=- \")([0-9\.]+)")
  dig +short www.free.fr @${testip}
  [[ $? -eq 0 ]] && echo -e "DNS Resolution ${GREEN}OK${NC}" || echo "${RED}DNS Resolution KO${NC}"
}

checkAdmin() {
  testip=$(grep -A1 ports ${CPSE} | tail -1 | grep -oPm1 "(?<=- \")([0-9\.]+)")
  res=$(curl -fs "http://${testip}:8053/admin/login.php") || true
  [[ 0 -le ${#res} ]] && res=$(curl -fs "http://${testip}:8053/admin/") || true
  [[ 0 -le ${#res} ]] && echo -e "http admin ${GREEN}OK${NC}" || echo -e "${RED}http admin KO ${NC}\n"
  res=$(curl -fsk "https://${testip}:1443/admin/login.php") || true
  [[ 0 -le ${#res} ]] && res=$(curl -fsk "https://${testip}:1443/admin/") || true
  [[ 0 -le ${#res} ]] && echo -e "https admin ${GREEN}OK${NC}" || echo -e "${RED}https admin KO ${NC}\n"
}
#Main
[[ ${1:-''} != "-t" ]] && buildContainer || true
docker compose logs
checkDns
checkAdmin
[[ ${1:-''} != "-t" ]] && docker compose stop || true