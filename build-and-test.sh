#!/usr/bin/env bash
set -e -u -o pipefail
set -x


#Functions
digDomains() {
	if [[ -f domain_list ]]; then
		n=0
		for d in $(<domain_list); do
			((n += 1))
			printf "%s : %s = %s\n" "${n}" "${d}" "$(dig +short ${d} @${1:-127.1.1.1} | tr '\n' ' ')"
			sleep ,2
		done
	else
		echo "domain_list not found"
	fi
}

if [[ "${1:-''}" == "dig" ]]; then
	digDomains ${2:-127.1.1.1}
	exit
fi

tox -c test/tox.ini
