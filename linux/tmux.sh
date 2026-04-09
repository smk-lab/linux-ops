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
source "${LIB_DIR}/tmux/check_session.sh"
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

# main 함수
main(){
    input_name
    check_session
    check_hosts_file
    parse_hosts
        
    for group in "${SECTION_ORDER[@]}"; do
        build_session "$group"
    done
}

# 구현부
main "$@"
tmux select-window -t "$SESSION:DPL"
tmux attach-session -t "$SESSION"