#!/bin/bash

check_hosts_file(){
    if [[ ! -f "$HOST_FILE" ]]; then
        echo "ERROR: $HOST_FILE 없음" >&2
        exit 1
    fi
}