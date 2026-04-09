#!/bin/bash
# ----------------------------------------
# tmuxc.sh
# 설명: custom이 된 tmux입니다.
# 사용법: ./tmuxc.sh
#
# 단축키
# prefix + [: 스크롤 모드 (vi키, q 종료)
# 마우스 copy&paste 사용 시 shift키 사용
# ----------------------------------------

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="$(cd "$(dirname "$0")/../lib" && pwd)"
LINUX_DIR="$(cd "$(dirname "$0")" && pwd)"

source "${LIB_DIR}/tmux/input_name.sh"
source "${LIB_DIR}/tmux/check_session_custom.sh"
source "${LIB_DIR}/check_hosts_file.sh"
source "${LIB_DIR}/parse_hosts.sh"
source "${LIB_DIR}/tmux/create_tmux.sh"
source "${LIB_DIR}/tmux/split_pane.sh"
source "${LIB_DIR}/tmux/custom.sh"
source "${LIB_DIR}/tmux/build_session.sh"

# ---------------------------------------------------
# HOST_FILE - hosts.ini 파일 위치
# VENV_GROUPS - openstack CLI용 venv 활성화 그룹
# KNOWN_GROUPS - 생성할 tmux window 그룹 목록
# INCLUDE_UNKNOWN - false 시 KNOWN_GROUPS 외 그룹 생성 제외
# custom - tmux 테마/옵션 설정 함수
#          window 단위 설정은 for문 안에 추가
# ---------------------------------------------------
HOST_FILE="${PROJECT_ROOT}/hosts.ini"
VENV_GROUPS=(DPL)
KNOWN_GROUPS=(DPL CTL COM AP DB PMT IBR EBR STR)
INCLUDE_UNKNOWN=false
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

# main 함수
main(){
    input_name
    check_session_custom
    check_hosts_file
    parse_hosts
        
    for group in "${SECTION_ORDER[@]}"; do
        build_session "$group"
    done
}

# 구현부
main "$@"
tmux select-window -t "$SESSION:DPL"
custom
tmux attach-session -t "$SESSION"