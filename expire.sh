#!/bin/sh

NODE_USER=sinovate

if [ "$(ps -e | grep sind | wc -l)" -eq "0" ]; then
    echo "Service sind do not started"
    exit 0
fi

cli="/home/$NODE_USER/sin-cli"
if [ ! "$(ps ax | grep "sind.*[.]sin[/]")" ]; then
    # multinode: try to get cli one of running infinitynode (sin1, sin2, sin3 ...)
    cli="/home/$NODE_USER/$(ps ax | grep "sind.*[.]sin[0-9]" | grep -o "sin[0-9]" | sort -u | head -n 1)"
    if ! test -f $cli; then
        echo "Error: $cli not found"
        exit
    fi
fi

days="$1"
cb=$($cli getblockcount)
$cli infinitynode show-infos | tr -d "\":," |\
    awk -v cb="$cb" -v d="$days" '$4>cb && $4<cb+720*d {print $5}' |\
    sort -n | uniq -c |\
    sed 's/1000000/big:/; s/500000/mid:/; s/100000/mini:/' |\
    awk '{print $2, $1}' ORS=', ' | sed 's/, $/\n/'
