#!/bin/bash
# ----------------------------------------
# tmux.sh
# 설명: hosts.ini 기반 tmux 세션 자동 생성
# 사용법: ./tmux.sh
# ----------------------------------------

read -rp "세션 이름: " input
SESSION="${input}"

# ~/.tmux.conf에 tmux.sh 설정 없으면 추가
if ! grep -q "# === tmux.sh ===" ~/.tmux.conf 2>/dev/null; then
    cat >> ~/.tmux.conf << 'EOF'

# === tmux.sh ===
set -g mouse on
set -g mode-keys vi

# 기본 설정
set -g pane-border-lines double
set -g pane-border-status top
set -g pane-border-format " #{pane_index} #{pane_current_command} "

# Prefix 표시 (Ctrl+b 누르면 status bar에 PREFIX 표시)
set -g status-left "[#S]#{?client_prefix, #[fg=black,bg=red,bold]PREFIX#[default],} "
set -g status-left-length 40
#set -g status-right " %m/%d %H:%M"
set -g status-right " cpu:#(top -bn1 | awk '/Cpu/{print 100-$8}')% ram:#(free | awk '/Mem:/{printf \"%.0f%%\",$3/$2*100}') %m/%d %H:%M"

# 현재 pane 강조
set -g allow-rename off
set -g automatic-rename off
set -g pane-active-border-style "fg=red,bold"
set -g pane-border-style "fg=grey"
set -g pane-border-format " #P #{pane_current_command} "
set -g pane-border-status top
set -g pane-border-lines double
EOF
fi

# 설정 즉시 반영
tmux source-file ~/.tmux.conf 2>/dev/null || true

HOST_FILE="/home/hosts.ini"

declare -A GROUP_HOSTS

SECTION_ORDER=()

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

tmux select-window -t "$SESSION:DPL"
tmux attach-session -t "$SESSION"
