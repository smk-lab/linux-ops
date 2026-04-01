#!/bin/bash
# ----------------------------------------
# tmux.sh
# 설명: hosts.ini 기반 tmux 세션 자동 생성
# 사용법: ./tmux.sh
# ----------------------------------------

read -rp "세션 이름: " input
SESSION="${input}"

HOST_FILE="/home/hosts.ini"

WIN_GROUPS=(
    "DPL:VENV"
    "CTL:SSH"
    "COM:SSH"
    "AP:SSH"
    "DB:SSH"
)

declare -A GROUP_HOSTS

parse_hosts() {
    local current_section=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        [[ -z "$line" || "$line" == "#"* ]] && continue
        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            current_section="${BASH_REMATCH[1]}"
        elif [[ -n "$current_section" ]]; then
            GROUP_HOSTS[$current_section]+="$line "
        fi
    done < "$HOST_FILE"
}

setup_group() {
    IFS=':' read -r win type <<< "$1"

    if [[ "$type" == "SSH" && -z "${GROUP_HOSTS[$win]}" ]]; then
        return
    fi

    read -ra hosts <<< "${GROUP_HOSTS[$win]}"
    local count=${#hosts[@]}
    [[ "$type" == "VENV" || $count -eq 0 ]] && count=1

    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux new-session -d -s "$SESSION" -n "$win"
    else
        tmux new-window -t "$SESSION" -n "$win"
    fi

    for ((i=1; i<count; i++)); do
        tmux split-window -v -t "$SESSION:$win"
    done
    tmux select-layout -t "$SESSION:$win" even-vertical

    for ((i=0; i<count; i++)); do
        if [[ "$type" == "SSH" ]]; then
            tmux send-keys -t "$SESSION:$win.$i" "ssh root@${hosts[$i]}" C-m
        else
            tmux send-keys -t "$SESSION:$win.$i" "source ~/venv/bin/activate" C-m
            tmux send-keys -t "$SESSION:$win.$i" "source /etc/kolla/admin-openrc.sh" C-m
            tmux send-keys -t "$SESSION:$win.$i" "clear" C-m
        fi
    done
}

parse_hosts

for group in "${WIN_GROUPS[@]}"; do
    setup_group "$group"
done

tmux select-window -t "$SESSION:DPL"
tmux attach-session -t "$SESSION"
