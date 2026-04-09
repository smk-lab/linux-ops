#!/bin/bash

check_session(){
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux a -t "$SESSION"
        exit 0
    fi
}
