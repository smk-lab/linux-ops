#!/bin/bash

#--------------------------------------------------------------------------
# hosts.sh - /etc/hosts 기반으로 hosts.ini 자동 생성
# 그룹 추가/수정 필요 시 아래 PATTERN_MAP과 GROUP_ORDER만 편집
# /etc/hosts에서 IPv6와 루프백 외에는 전부 가져오기 때문에 필요 없는 부분 제거 필요
#--------------------------------------------------------------------------

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINUX_DIR="$(cd "$(dirname "$0")" && pwd)"

#=====================================================
# [CONFIG]
#=====================================================
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

#=====================================================
# [FUNCTIONS]
#=====================================================

build_hosts_prefix_map() {
    declare -gA PREFIX_TO_GROUP
    for group in "${!PATTERN_MAP[@]}"; do
        IFS=',' read -ra patterns <<< "${PATTERN_MAP[$group]}"
        for pattern in "${patterns[@]}"; do
            PREFIX_TO_GROUP[$pattern]=$group
        done
    done
}

read_etc_hosts() {
    declare -gA GROUP_IPS
    declare -ga UNKNOWN_GROUPS
    while read -r ip hostname _; do
        [[ -z "$ip" || "$ip" == "#"* ]] && continue
        if [[ "$ip" == "127."* || "$ip" == *"::"* || "$ip" == "ff"* ]]; then
            [[ "$hostname" != *"dpl"* ]] && continue
        fi

        prefix=$(echo "$hostname" | sed 's/[0-9]*$//' | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]')
        [[ -z "$prefix" ]] && continue

        group="${PREFIX_TO_GROUP[$prefix]}"

        if [[ -n "$group" ]]; then
            GROUP_IPS[$group]+="$ip"$'\n'
        else
            fallback=$(echo "$prefix" | tr '[:lower:]' '[:upper:]')
            GROUP_IPS[$fallback]+="$ip"$'\n'
            if [[ ! " ${UNKNOWN_GROUPS[*]} " =~ " $fallback " ]]; then
                UNKNOWN_GROUPS+=("$fallback")
            fi
        fi
    done < /etc/hosts
}

write_hosts_output() {
    for group_raw in "${GROUP_ORDER[@]}"; do
        group=$(echo "$group_raw" | tr -d '[:space:]')
        [[ "$group" != "DPL" && -z "${GROUP_IPS[$group]}" ]] && continue
        
        echo "[$group]"
        
        if [[ -n "${GROUP_IPS[$group]}" ]]; then
            echo -n "${GROUP_IPS["$group"]}"
        elif [[ "$group" == "DPL" ]]; then
            echo "127.0.0.1"
        fi
        
        echo 
    done

    for group in $(printf '%s\n' "${UNKNOWN_GROUPS[@]}" | sort); do
        echo "[$group]"
        echo -n "${GROUP_IPS["$group"]}"
        echo
    done
}

#=====================================================
# [MAIN]
#=====================================================
main() {
    build_hosts_prefix_map
    read_etc_hosts
    write_hosts_output > "$OUTPUT"
}

#======================================================
# [ENTRY POINT]
#======================================================
main "$@"
find "$(dirname "$0")" -name "*.sh" -exec chmod +x {} \;
