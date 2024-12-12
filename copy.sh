#!/usr/bin/env bash

set -e

if [ -e "config.sh" ]
then
    source config.sh
else
    echo "create config.sh and set MISTER_IP as desired" >&2
    exit 1
fi

set -x
rsync \
    -v \
    --rsh="sshpass -p 1 ssh" \
    output_files/Osborne.rbf \
    "root@${MISTER_IP}:/media/fat/_Computer/Osborne.rbf"
