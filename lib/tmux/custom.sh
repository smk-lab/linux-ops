#!/bin/bash

custom(){
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

    for win in $(tmux list-windows -t "$SESSION" -F "#W"); do
        tmux set -t "$SESSION:$win" pane-border-status top
        tmux set -t "$SESSION:$win" pane-border-format " #P #{pane_current_command} "
        tmux set -t "$SESSION:$win" pane-border-lines double
        tmux set -t "$SESSION:$win" pane-active-border-style "fg=red bold"
        tmux set -t "$SESSION:$win" pane-border-style "fg=grey"
        tmux set -t "$SESSION:$win" pane-base-index 1
    done
}