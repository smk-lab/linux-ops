#!/bin/bash

read_etc_hosts() {
    declare -gA GROUP_IPS
    declare -ga UNKNOWN_GROUPS
    while read -r ip hostname _; do
        [[ -z "$ip" || "$ip" == "#"* ]] && continue
        if [[ "$ip" == "127."* || "$ip" == *"::"* || "$ip" == "ff"* ]]; then
            [[ "$hostname" != *"dpl"* ]] && continue
        fi

        prefix=$(echo "$hostname" | sed 's/[0-9]*$//' | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]')
        [[ -z "$prefix" ]] && continue

        group="${PREFIX_TO_GROUP[$prefix]}"

        if [[ -n "$group" ]]; then
            GROUP_IPS[$group]+="$ip"$'\n'
        else
            fallback=$(echo "$prefix" | tr '[:lower:]' '[:upper:]')
            GROUP_IPS[$fallback]+="$ip"$'\n'
            if [[ ! " ${UNKNOWN_GROUPS[*]} " =~ " $fallback " ]]; then
                UNKNOWN_GROUPS+=("$fallback")
            fi
        fi
    done < /etc/hosts
}