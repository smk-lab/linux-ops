#!/bin/bash
# ----------------------------------------
# tmux.sh
# 설명: hosts.ini 기반 tmux 세션 자동 생성
# 사용법: ./tmux.sh
# ----------------------------------------

read -rp "세션 이름: " input
SESSION="${input}"

HOST_FILE="/home/hosts.ini"

if [[ ! -f "$HOST_FILE" ]]; then
    echo "ERROR: There is no $HOST_FILE" >&2
    exit 1
fi

declare -A GROUP_HOSTS

SECTION_ORDER=()

apply_tmux_settings() {
    tmux set -t "$SESSION" -g default-terminal "screen-256color"
    tmux set -t "$SESSION" -ga terminal-overrides ",xterm-256color:Tc"
    tmux set -t "$SESSION" mouse on
    tmux set -t "$SESSION" mode-keys vi
    tmux set -t "$SESSION" pane-border-status top
    tmux set -t "$SESSION" pane-border-format " #P #T "
    tmux set -t "$SESSION" status-left "[#S]#{?client_prefix, #[fg=black bg=red bold]PREFIX#[default],}"
    tmux set -t "$SESSION" status-left-length 40
    tmux set -t "$SESSION" allow-rename off
    tmux set -t "$SESSION" automatic-rename off
}

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

    if tmux has-session -t "$SESSION" 2>/dev/null; then
        apply_tmux_settings
        tmux attach-session -t "$SESSION"
        exit 0
    fi
}

setup_group() {
    local win="$1"
    local type="SSH"
    local pane_base
    pane_base=$(tmux show-option -gv pane-base-index 2>/dev/null || echo 0)

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

    if [[ "$win" == "DPL" ]]; then
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
            local pane_idx=$(( j + pane_base ))
            if [[ "$type" == "SSH" ]]; then
                tmux send-keys -t "$SESSION:$win_name.$pane_idx" "ssh root@${hosts[$host_idx]}" C-m
            else
                tmux send-keys -t "$SESSION:$win_name.$pane_idx" "source ~/venv/bin/activate" C-m
                tmux send-keys -t "$SESSION:$win_name.$pane_idx" "source /etc/kolla/admin-openrc.sh" C-m
                tmux send-keys -t "$SESSION:$win_name.$pane_idx" "clear" C-m
            fi
        done
    done
}

parse_hosts

for group in "${SECTION_ORDER[@]}"; do
    setup_group "$group"
done

apply_tmux_settings
tmux select-window -t "$SESSION:DPL"
tmux attach-session -t "$SESSION"
