#!/bin/bash

input_name() {
    read -rp "세션 이름: " input
    SESSION="${input}"
}