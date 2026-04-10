#!/bin/bash
set -e
set -u
set -o pipefail

# ----------------------------------------------------------------------------
# tmuxc.sh
# 설명: custom이 된 tmux입니다.
# 사용법: ./tmuxc.sh
#
# 단축키
# prefix + [: 스크롤 모드 (vi키, q 종료)
# 마우스 copy&paste 사용 시 shift키 사용
# -----------------------------------------------------------------------------

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINUX_DIR="$(cd "$(dirname "$0")" && pwd)"

#===============================================================================
# [CONFIG]
#===============================================================================
# HOST_FILE - hosts.ini 파일 위치
# VENV_GROUPS - openstack CLI용 venv 활성화 그룹
# KNOWN_GROUPS - 생성할 tmux window 그룹 목록
# INCLUDE_UNKNOWN - false 시 KNOWN_GROUPS 외 그룹 생성 제외
# custom - tmux 테마/옵션 설정 함수
#          window 단위 설정은 for문 안에 추가
# ------------------------------------------------------------------------------
HOST_FILE="${PROJECT_ROOT}/hosts.ini"
VENV_GROUPS=(DPL)
KNOWN_GROUPS=(DPL CTL COM AP DB PMT IBR EBR STR)
INCLUDE_UNKNOWN=false

#===============================================================================
# [FUNCTIONS]
#===============================================================================
input_name() {
    read -rp "세션 이름: " input
    SESSION="${input}"
}

check_session(){
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux a -t "$SESSION"
        exit 0
    fi
}

check_hosts_file(){
    if [[ ! -f "$HOST_FILE" ]]; then
        echo "ERROR: $HOST_FILE 없음" >&2
        exit 1
    fi
}

parse_hosts() {
    declare -g -A GROUP_HOSTS
    declare -g -a SECTION_ORDER

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

create_tmux() {
    local win_name="$1"

    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux new-session -d -s "$SESSION" -n "$win_name"
    else
        tmux new-window -t "$SESSION" -n "$win_name"
    fi
}

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

build_session() {
    local win="$1"
    local type="SSH"
    local pane_base=$(tmux show-option -gv pane-base-index 2>/dev/null || echo 0)

    if [[ "$INCLUDE_UNKNOWN" == false ]]; then
        [[ ! " ${KNOWN_GROUPS[*]} " =~ "$win" ]] && return
    fi

    for venv_group in "${VENV_GROUPS[@]}"; do
        [[ "$win" == "$venv_group" ]] && type="VENV"
    done

    if [[ "$type" == "SSH" && -z "${GROUP_HOSTS[$win]}" ]]; then
        return
    fi

    read -ra hosts <<< "${GROUP_HOSTS[$win]}"
    local count=${#hosts[@]}
    [[ "$type" == "VENV" || $count -eq 0 ]] && count=1

    for ((i=0; i<count; i+=4)); do
        local win_name="$win"
        (( i > 0 )) && win_name="${win}-$((i/4 + 1))"

        local remaining=$(( count - i ))
        local current_win_count=$(( remaining > 4 ? 4 : remaining ))
        local chunk=("${hosts[@]:i:current_win_count}")

        create_tmux "$win_name"
        split_pane "$win_name" "$current_win_count"
        
        for ((j=0; j<${#chunk[@]}; j++)); do
            local pane=$(( pane_base + j ))
            if [[ "$type" == "SSH" ]]; then
                tmux send-keys -t "$SESSION:$win_name.$pane" "ssh ${chunk[$j]}" Enter
            elif [[ "$type" == "VENV" ]]; then
                tmux send-keys -t "$SESSION:$win_name.$pane" "source ~/venv/bin/activate" Enter
                tmux send-keys -t "$SESSION:$win_name.$pane" "source /etc/kolla/admin-openrc.sh" Enter
            fi
        done
    done
}



#===============================================================================
# [MAIN]
#===============================================================================
main(){
    input_name
    check_session
    check_hosts_file
    parse_hosts
        
    for group in "${SECTION_ORDER[@]}"; do
        build_session "$group"
    done
}

#===============================================================================
# [ENTRY POINT]
#===============================================================================
main "$@"
tmux select-window -t "$SESSION:DPL"
tmux attach-session -t "$SESSION"
