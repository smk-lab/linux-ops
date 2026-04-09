#!/bin/bash

setup_ssh_key() {
    if [ ! -f ~/.ssh/id_rsa]; then
        ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
    fi
}