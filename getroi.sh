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

common=$($cli masternodelist full 2>/dev/null | tr -d "\"," | grep " ENABLED")
[ "$common" ] || exit

nodetypes=$(echo "$common" | awk '/[0-9]+/{print $12}' | sort -n | uniq -c)
big=$(echo "$nodetypes" | awk '/1000000$/{print $1}')
mid=$(echo "$nodetypes" | awk '/500000$/{print $1}')
min=$(echo "$nodetypes" | awk '/100000$/{print $1}')
bigroi=$(( (1752*720*365/$big)/10000-100 ))
midroi=$(( (838*720*365/$mid)/5000-100 ))
minroi=$(( (160*720*365/$min)/1000-100 ))

echo "ROI: big $bigroi%, mid $midroi%, mini $minroi%"
