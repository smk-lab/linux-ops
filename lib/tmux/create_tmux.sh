#!/bin/bash

create_tmux() {
    local win_name="$1"

    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux new-session -d -s "$SESSION" -n "$win_name"
    else
        tmux new-window -t "$SESSION" -n "$win_name"
    fi
}