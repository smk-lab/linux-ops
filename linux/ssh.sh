#!/bin/bash
set -e
set -u
set -o pipefail

#-------------------------------------------------------------------------------
# ssh.sh
# 설명 : 초기 SSH 시도 시 keygen 및 키교환
#-------------------------------------------------------------------------------

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINUX_DIR="$(cd "$(dirname "$0")" && pwd)"

#===============================================================================
# [CONFIG]
#===============================================================================
# HOST_FILE - hosts.ini 파일 위치
# SSH_USER - 접속을 위한 SSH 계정
# SSH_PORT - 접속을 위한 SSH 포트
# SSH_TIMOUT - 네트워크 상태에 따라 증가
# SSH_RETRY - 네트워크 상태에 따라 증가
#-------------------------------------------------------------------------------
HOST_FILE="${PROJECT_ROOT}/hosts.ini"
SSH_USER="root"
SSH_PORT="22"
SSH_TIMEOUT="3"
SSH_RETRY="1"

# ==============================================================================
# [COLORS] - 터미널 출력 색상 정의
# ==============================================================================
RED='\033[0;31m'    # 에러/실패
GREEN='\033[0;32m'  # 성공/완료
NC='\033[0m'        # No Color (색상 초기화)

#===============================================================================
# [FUNCTIONS]
#===============================================================================
SUCCESS_CNT=0
FAILURE_CNT=0

setup_ssh_key() {
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
    fi
}

get_hosts_ip() {
    awk '
        /^\[/ {next} /^\s*#/ || /^\s*$/ { next } { print $1 }' "${HOST_FILE}"
}

exchange_keys() {
    local password
    read -sp "SSH 비밀번호 입력: " password
    echo

    setup_ssh_key

    while IFS= read -r host; do
        if sshpass -p "${password}" ssh-copy-id \
            -o StrictHostKeyChecking=accept-new \
            -o ConnectTimeout="${SSH_TIMEOUT}" \
            -o ConnectionAttempts="${SSH_RETRY}" \
            -i ~/.ssh/id_rsa.pub \
            -p "${SSH_PORT}" \
            "${SSH_USER}@${host}" > /dev/null 2>&1; then
            printf "${GREEN}%-8s${NC} %s\n" "[OK]" "${host}"
            count_result 0
        else
            printf "${RED}%-8s${NC} %s\n" "[FAIL]" "${host}"
            count_result 1
        fi
    done < <(get_hosts_ip)
}

count_result() {
    if [ $1 -eq 0 ]; then
        SUCCESS_CNT=$(( SUCCESS_CNT + 1 ))
    else
        FAILURE_CNT=$(( FAILURE_CNT + 1 ))
    fi
}

print_summary() {
    local total=$(( SUCCESS_CNT + FAILURE_CNT ))
    echo "=========================================="
    echo "  Execution Summary"
    echo "------------------------------------------"
    echo "  Total   : $total"
    echo -e "  ${GREEN}Success : $SUCCESS_CNT"
    echo -e "  ${RED}Failed  : $FAILURE_CNT${NC}"
    echo "=========================================="
    echo ""
}

#===============================================================================
# [MAIN]
#===============================================================================
main() {
    echo "=== 대상 호스트 ==="
    get_hosts_ip
    echo "=================="
    exchange_keys
    sudo systemctl restart sshd
}


#===============================================================================
# [ENTRY POINT]
#===============================================================================
main "$@"
print_summary