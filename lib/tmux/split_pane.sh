#!/bin/bash

split_pane() {
    local win_name="$1"
    local count="$2"

    for ((j=1; j<count; j++)); do
        tmux split-window -v -t "$SESSION:$win_name"
    done

    if (( count != 4 )); then
        tmux select-layout -t "$SESSION:$win_name" even-vertical
    else
        tmux select-layout -t "$SESSION:$win_name" tiled
    fi
}