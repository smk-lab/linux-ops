#!/bin/bash
# test_password.sh

HOST_FILE="../hosts.ini"

PASSWORD_RULE_ENABLE="true"  # false 로 바꿔서도 테스트


get_hosts_ip() {
    awk '
        /^\[/ {next} /^\s*#/ || /^\s*$/ { next } { print $1 }' "${HOST_FILE}"
}

get_password() {
    local host=$1
    local password=$2
    local prefix=$3
    local suffix=$4

    if [ "${PASSWORD_RULE_ENABLE}" = true ]; then
        local last_octet
        last_octet=$(echo "${host}" | awk -F. '{print $4}')
        echo "${prefix}${last_octet}${suffix}"
    else
        echo "${password}"
    fi
}

exchange_keys() {
    local password=""

    if [ "${PASSWORD_RULE_ENABLE}" = true ]; then
        local prefix suffix
        read -sp "PASSWORD PREFIX: " prefix
        echo
        read -sp "PASSWORD SUFFIX: " suffix
        echo
    else
        read -sp "SSH PASSWORD: " password
        echo
    fi

    while IFS= read -r host; do
        local pw
        pw=$(get_password "${host}" "${password}" "${prefix:-}" "${suffix:-}")
        echo "${host} → ${pw}"
    done < <(get_hosts_ip)
}

main(){
    exchange_keys
}

main "$@"
