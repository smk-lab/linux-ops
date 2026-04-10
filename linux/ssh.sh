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
#-------------------------------------------------------------------------------
HOST_FILE="${PROJECT_ROOT}/hosts.ini"
SSH_USER="root"
SSH_PORT="22"
#===============================================================================
# [FUNCTIONS]
#===============================================================================
setup_ssh_key() {
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
    fi
}

get_hosts_ip() {
    awk '
        /^\[/      { skip=0; next }
        skip || /^\s*#/ || /^\s*$/ { next }
        { print $1 }
    ' "${HOST_FILE}"
}

exchange_keys() {
    local password
    read -sp "SSH 비밀번호 입력: " password
    echo

    setup_ssh_key

    while IFS= read -r host; do
        if sshpass -p "${password}" ssh-copy-id \
            -o StrictHostKeyChecking=accept-new \
            -i ~/.ssh/id_rsa.pub \
            -p "${SSH_PORT}" \
            "${SSH_USER}@${host}" > /dev/null 2>&1; then
            echo "[OK]     ${host}"
        else
            echo "[FAIL]   ${host}"
        fi
    done < <(get_hosts_ip)
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