#!/bin/bash

check_session_custom(){
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        custom
        tmux a -t "$SESSION"
        exit 0
    fi
}