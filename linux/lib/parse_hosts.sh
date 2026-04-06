#!/bin/bash

parse_hosts() {
    local current_section=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        [[ -z "$line" || "$line" == "#"* ]] && continue

        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            current_section="${BASH_REMATCH[1]}"
            SECTION_ORDER+=("$current_section")
        elif [[ -n "$current_section" ]]; then
            GROUP_HOSTS[$current_section]+="$line "
        fi
    done < "$HOST_FILE"
}
