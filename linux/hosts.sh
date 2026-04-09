#!/bin/bash

#--------------------------------------------------------------------------
# hosts.sh - /etc/hosts 기반으로 hosts.ini 자동 생성
# 그룹 추가/수정 필요 시 아래 PATTERN_MAP과 GROUP_ORDER만 편집
# /etc/hosts에서 IPv6와 루프백 외에는 전부 가져오기 때문에 필요 없는 부분 제거 필요
#--------------------------------------------------------------------------

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="$(cd "$(dirname "$0")/../lib" && pwd)"
LINUX_DIR="$(cd "$(dirname "$0")" && pwd)"

source "${LIB_DIR}/hosts/build_hosts_prefix_map.sh"
source "${LIB_DIR}/hosts/read_etc_hosts.sh"
source "${LIB_DIR}/hosts/write_hosts_output.sh"



#-----------------------------------------------------
# OUTPUT - hosts.ini 파일 생성 경로
# GROUP_ORDER - hosts.ini 출력 순서
# PATTERN_MAP - 호스트명 패턴 → 그룹 매핑
#-----------------------------------------------------

OUTPUT="$(dirname "$0")/../hosts.ini"
GROUP_ORDER=(DPL CTL COM AP DB PMT IBR EBR STR)
declare -A PATTERN_MAP=(
    [DPL]="dpl,deploy"
    [CTL]="ctl,ctrl,controller"
    [COM]="com,computer"
    [AP]="AP,ap"
    [DB]="DB,db,database"
    [PMT]="pmt,prometheus,monitor"
    [IBR]="ibr,internal"
    [EBR]="ebr,external"
    [STR]="str,sto,storage,ceph"  
)


# 구현부
main() {
    build_hosts_prefix_map
    read_etc_hosts
    write_hosts_output > "$OUTPUT"
}

# 호출
main "$@"

find "$(dirname "$0")" -name "*.sh" -exec chmod +x {} \;
