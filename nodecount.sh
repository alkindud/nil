#!/bin/sh

NODE_USER=$(whoami)

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

common=$($cli masternodelist full 2>/dev/null | tr -d "\",")
[ "$common" ] || exit
encommon=$(echo "$common" | grep " ENABLED")
nodecount=$($cli masternode count all 2>/dev/null | awk '{print "\\e[92m" $4 "\\e[39m / \\e[93m" $2 "\\e[39m"}')
[ "$nodecount" ] || exit

nodetypes=$(echo "$common" | awk '/[0-9]+/{print $12}' | sort -n | uniq -c)
big=$(echo "$nodetypes" | awk '/1000000$/{print $1}')
mid=$(echo "$nodetypes" | awk '/500000$/{print $1}')
min=$(echo "$nodetypes" | awk '/100000$/{print $1}')
bigroi=$(( (1752*720*365/$big)/10000-100 ))
midroi=$(( (838*720*365/$mid)/5000-100 ))
minroi=$(( (160*720*365/$min)/1000-100 ))

ennodetypes=$(echo "$encommon" | awk '/[0-9]+/{print $12}' | sort -n | uniq -c)
enbig=$(echo "$ennodetypes" | awk '/1000000$/{print $1}')
enmid=$(echo "$ennodetypes" | awk '/500000$/{print $1}')
enmin=$(echo "$ennodetypes" | awk '/100000$/{print $1}')
enbigroi=$(( (1752*720*365/$enbig)/10000-100 ))
enmidroi=$(( (838*720*365/$enmid)/5000-100 ))
enminroi=$(( (160*720*365/$enmin)/1000-100 ))

echo "Infinitynodes: $nodecount ( big: \e[92m$enbig $enbigroi%\e[39m / \e[93m$big $bigroi%\e[39m, mid: \e[92m$enmid $enmidroi%\e[39m / \e[93m$mid $midroi%\e[39m, mini: \e[92m$enmin $enminroi%\e[39m / \e[93m$min $minroi%\e[39m )"
