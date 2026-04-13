#!/bin/bash

#-------------------------------------------------------------------------------
# ssh_config.sh
# Description : ssh_config 원격 수정 스크립트
#-------------------------------------------------------------------------------

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINUX_DIR="$(cd "$(dirname "$0")" && pwd)"

#===============================================================================
# [CONFIG]
#===============================================================================
# HOST_FILE - hosts.ini 파일 위치
#
#-------------------------------------------------------------------------------
HOST_FILE="${PROJECT_ROOT}/hosts.ini"

SSH_USER="root"
SSH_PORT="22"
SSH_TIMEOUT="5"
SSHD_CONFIG=(
    "PermitRootLogin prohibit-password"
    #"PubkeyAuthentication yes"
    "PasswordAuthentication no"
)

# ==============================================================================
# [COLORS] - 터미널 출력 색상 정의
# ==============================================================================
RED='\033[0;31m'    # 에러/실패
GREEN='\033[0;32m'  # 성공/완료
NC='\033[0m'        # No Color (색상 초기화)

#===============================================================================
# [FUNCTIONS]
#===============================================================================
get_hosts_ip() {
    awk '
        /^\[/ {next} /^\s*#/ || /^\s*$/ { next } { print $1 }' "${HOST_FILE}"
}

check_ssh() {
    local host=$1
    if ! ssh -o BatchMode=yes \
             -o ConnectTimeout="${SSH_TIMEOUT}" \
             "${SSH_USER}@${host}" exit 2>/dev/null; then
        printf "${RED}%-8s${NC} %s\n" "[FAIL]" "${host}"
        echo "Please execute script"
        echo "./ssh.sh"
        read -rp "continue (yes/no): " skip
        if [ "${skip}" = "no" ]; then
            exit 1 
        else
            return 1
        fi
    fi
}

apply_sshd_config() {
    local host=$1

    for etnry in "${!SSHD_CONFIG[@]}"; do
        local key="{etnry%% *}"
        local value="${entry#* }"
        ssh "${SSH_USER}@${host}" \
            "sed -i \"s/^#\?\s*${key}\s.*/${key} ${value}/\" /etc/ssh/sshd_config"
    done
}

#===============================================================================
# [MAIN]
#===============================================================================
main() {
    while IFS= read -r host; do
        check_ssh "$host" || continue
        apply_sshd_config "$host"
    done < <(get_hosts_ip)
}

#===============================================================================
# [ENTRY POINT]
#===============================================================================
main "$@"