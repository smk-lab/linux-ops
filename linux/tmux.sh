#!/bin/bash
# ----------------------------------------
# tmux.sh
# 설명: hosts.ini 기반 tmux 세션 자동 생성
# 사용법: ./tmux.sh
# ----------------------------------------

source "$(dirname "$0")/lib/parse_hosts.sh"

read -rp "세션 이름: " input
SESSION="${input}"

HOST_FILE="$(dirname "$0")/../hosts.ini"

if tmux has-session -t "$SESSION" 2>/dev/null; then
    apply_tmux_settings
    tmux attach-session -t "$SESSION"
    exit 0
fi

if [[ ! -f "$HOST_FILE" ]]; then
    echo "ERROR: There is no $HOST_FILE" >&2
    exit 1
fi

declare -A GROUP_HOSTS

SECTION_ORDER=()

setup_group() {
    local win="$1"
    local type="SSH"

    [[ "$win" == "DPL" ]] && type="VENV"

    if [[ "$type" == "SSH" && -z "${GROUP_HOSTS[$win]}" ]]; then
        return
    fi

    read -ra hosts <<< "${GROUP_HOSTS[$win]}"
    local count=${#hosts[@]}
    [[ "$type" == "VENV" || $count -eq 0 ]] && count=1

    for ((i=0; i<count; i+=4)); do
        local win_name="$win"
        if (( i > 0 )); then
            win_name="${win}-$((i/4 + 1))"
        fi

    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux new-session -d -s "$SESSION" -n "$win_name"
    else
        tmux new-window -t "$SESSION" -n "$win_name"
    fi

    local remaining=$(( count - i ))
    local current_win_count=$(( remaining > 4 ? 4 : remaining ))

    for ((j=1; j<current_win_count; j++)); do
        tmux split-window -v -t "$SESSION:$win_name"
    done
    
    if (( current_win_count != 4 )); then
        tmux select-layout -t "$SESSION:$win_name" even-vertical
    else
        tmux select-layout -t "$SESSION:$win_name" tiled    
    fi

    for ((j=0; j<current_win_count; j++)); do
        local host_idx=$(( i + j ))
        if [[ "$type" == "SSH" ]]; then
            tmux send-keys -t "$SESSION:$win_name.$j" "ssh root@${hosts[$host_idx]}" C-m
        else
            tmux send-keys -t "$SESSION:$win_name.$j" "source ~/venv/bin/activate" C-m
            tmux send-keys -t "$SESSION:$win_name.$j" "source /etc/kolla/admin-openrc.sh" C-m
            tmux send-keys -t "$SESSION:$win_name.$j" "clear" C-m
        fi
    done
done
}

parse_hosts

for group in "${SECTION_ORDER[@]}"; do
    setup_group "$group"
done

tmux select-window -t "$SESSION:DPL"
tmux attach-session -t "$SESSION"
