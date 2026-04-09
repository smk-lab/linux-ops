#!/bin/bash

build_hosts_prefix_map() {
    declare -gA PREFIX_TO_GROUP
    for group in "${!PATTERN_MAP[@]}"; do
        IFS=',' read -ra patterns <<< "${PATTERN_MAP[$group]}"
        for pattern in "${patterns[@]}"; do
            PREFIX_TO_GROUP[$pattern]=$group
        done
    done
}