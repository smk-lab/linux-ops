#!/bin/bash

write_hosts_output() {
    for group_raw in "${GROUP_ORDER[@]}"; do
        group=$(echo "$group_raw" | tr -d '[:space:]')
        [[ "$group" != "DPL" && -z "${GROUP_IPS[$group]}" ]] && continue
        
        echo "[$group]"
        
        if [[ -n "${GROUP_IPS[$group]}" ]]; then
            echo -n "${GROUP_IPS["$group"]}"
        elif [[ "$group" == "DPL" ]]; then
            echo "127.0.0.1"
        fi
        
        echo 
    done

    for group in $(printf '%s\n' "${UNKNOWN_GROUPS[@]}" | sort); do
        echo "[$group]"
        echo -n "${GROUP_IPS["$group"]}"
        echo
    done
}