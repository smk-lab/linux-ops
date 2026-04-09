#!/bin/bash

send_command(){
    local win_name="$1"
    local type="$2"
    local pane_base="$3"
    shift 3
    local hosts=("$@")

    for ((j=0; j<${#hosts[@]}; j++)); do
        local pane_idx=$(( j + pane_base ))
        if [[ "$type" == "SSH" ]]; then
            tmux send-keys -t "$SESSION:$win_name.%pane_idx" "ssh root@${hosts[$j]}" C-m
        else
            tmux send-keys -t "$SESSION:$win_name.$pane_idx" "source ~/venv/bin/activate" C-m
            tmux send-keys -t "$SESSION:$win_name.$pane_idx" "source /etc/kolla/admin-openrc.sh" C-m
            tmux send-keys -t "$SESSION:$win_name.$pane_idx" "clear" C-m
        fi
    done
}