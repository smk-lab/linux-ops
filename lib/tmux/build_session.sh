#!/bin/bash

build_session() {
    local win="$1"
    local type="SSH"
    local pane_base=$(tmux show-option -gv pane-base-index 2>/dev/null || echo 0)

    if [[ "$INCLUDE_UNKNOWN" == false ]]; then
        [[ ! " ${KNOWN_GROUPS[*]} " =~ "$win" ]] && return
    fi

    for venv_group in "${VENV_GROUPS[@]}"; do
        [[ "$win" == "$venv_group" ]] && type="VENV"
    done

    if [[ "$type" == "SSH" && -z "${GROUP_HOSTS[$win]}" ]]; then
        return
    fi

    read -ra hosts <<< "${GROUP_HOSTS[$win]}"
    local count=${#hosts[@]}
    [[ "$type" == "VENV" || $count -eq 0 ]] && count=1

    for ((i=0; i<count; i+=4)); do
        local win_name="$win"
        (( i > 0 )) && win_name="${win}-$((i/4 + 1))"

        local remaining=$(( count - i ))
        local current_win_count=$(( remaining > 4 ? 4 : remaining ))
        local chunk=("${hosts[@]:i:current_win_count}")

        create_tmux "$win_name"
        split_pane "$win_name" "$current_win_count"
        
        for ((j=0; j<${#chunk[@]}; j++)); do
            local pane=$(( pane_base + j ))
            if [[ "$type" == "SSH" ]]; then
                tmux send-keys -t "$SESSION:$win_name.$pane" "ssh ${chunk[$j]}" Enter
            elif [[ "$type" == "VENV" ]]; then
                tmux send-keys -t "$SESSION:$win_name.$pane" "source ~/venv/bin/activate" Enter
                tmux send-keys -t "$SESSION:$win_name.$pane" "source /etc/kolla/admin-openrc.sh" Enter
            fi
        done
    done
}