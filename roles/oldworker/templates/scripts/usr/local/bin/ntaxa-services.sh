#!/bin/bash

if [[ "$1" == "-h" ]]; then
    echo "Usage: "`basename "$0"`" - change runed services
"
    exit
fi

sysv-rc-conf