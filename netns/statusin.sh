#!/bin/bash

NODE_USER="sinovate"
COLOR=y

set -e

if [ "$COLOR" = "y" ]; then
    R=$'\e[91m'; G=$'\e[92m'; Y=$'\e[93m'; P=$'\e[95m'; NC=$'\e[0m'
else
    R=""; G=""; Y=""; P=""; NC=""
fi

if [ "$(ps -e | grep sind | wc -l)" -eq "0" ]; then
    echo "Service sind do not started"
    exit
fi

address="$@"
sindirs=$(find /home/$NODE_USER -maxdepth 1 -name '.sin*' -type d -printf '%f\n' | sort)
if [ "$address" ]; then
    sindirs=".$(ps ax | grep -o "[.]sin[0-9]*/" | grep -o "sin[0-9]*" | sort -u | head -n 1)"
fi

for i in $sindirs; do
    if [ "$i" = ".sin" ]; then
        cli="/home/$NODE_USER/sin-cli"
    else
        cli="/home/$NODE_USER/${i#.}"
        if ! test -f $cli; then
            echo -e "${i#.}:\t${R}$cli not found${NC}"
            continue
        fi
    fi

    if [ ! "$address" ]; then
        # my vps
        mypeer=$($cli infinitynode mypeerinfo 2>&1 | grep -v "[{}]" | sed 's/  //; s/"//g')
        if [ "$(echo $mypeer | grep "Could not connect")" ]; then
            echo -e "${i#.}:\t${R}not started${NC}"
            continue
        fi
        if [ ! "$(echo $mypeer | grep "MyPeerInfo")" ]; then
            echo -e "${i#.}:\t${R}$(echo "$mypeer" | grep -v "error")${NC}"
            continue
        fi
        sync=$($cli mnsync status 2>/dev/null | awk '/IsBlockchainSynced/{print $2}' | tr -d ",")
        if [ "$sync" = "false" ]; then
            cb=$($cli getblockcount 2>/dev/null)
            echo -e "${i#.}:\t${Y}Blockchain synchronization:${NC} $cb"
            continue
        fi
        if [ "$(echo "$mypeer" | grep "is running")" ]; then
            address=$(echo "$mypeer" | cut -d ":" -f 3 | tr -d " " | cut -d "-" -f 1)
        else
            address=""
            echo -e "${i#.}:\t${Y}${mypeer:12}${NC}"
            continue
        fi
    fi

    cb=$($cli getblockcount 2>/dev/null)
    infos=$($cli infinitynode show-infos 2>/dev/null | grep -P "${address// /|}" | awk -v cb="$cb" '$4 > cb' | sort -k4 | tr -d "\",")

    while read j; do
        [ "$j" ] || continue
        address=$(echo "$j" | cut -d " " -f 2)

        firstblock=$(echo "$j" | cut -d " " -f 3)
        lastblock=$(echo "$j" | cut -d " " -f 4)
        lifetime=$(( $cb - $firstblock ))
        lastday=`date -u -d "+$(( ($lastblock-$cb)*2 )) minutes" +%F`

        nodetype=$(echo "$j" | cut -d " " -f 5)
        mynodescount=$(echo "$j" | cut -d " " -f 10)
        nr[1]=560; nr[5]=838; nr[10]=1752
        idreward=$(echo "$j" | cut -d " " -f 6)
        reward=${nr[$idreward]}
        coinsleft=$(( (720*365-$lifetime)/$mynodescount*$reward ))
        [ $coinsleft -lt 0 ] && coinsleft="0"

        lastpayblock=$(echo "$j" | cut -d " " -f 8)
        if [ "$lastpayblock" = "-1" ]; then
            deltapayblock="${Y}???${NC}"
        else
            deltapayblock=$((cb - lastpayblock))
            # possible lag of 5 blocks
            [ $deltapayblock -gt $((mynodescount+5)) ] &&\
                deltapayblock="${Y}$deltapayblock${NC}" ||\
                deltapayblock="${G}$deltapayblock${NC}"
        fi

        ip=$(echo "$j" | cut -d " " -f 13)

        # shortening
        nodetype=${nodetype/1000000/big}
        nodetype=${nodetype/500000/mid}
        nodetype=${nodetype/100000/min}
        [ "$(echo $mypeer | grep "is running")" ] && mypeer="${G}Running${NC}"
        lastblock="${P}$lastblock${NC}"
        lastday="${P}$lastday${NC}"
        coinsleft="${P}$((coinsleft/1000))k${NC}"
        sync=${sync/true/${G}Sync finished${NC}}

        if [ "$mypeer" ]; then
            printf "%s:\t%s %s %s %s %s %s %s %s %s\n" \
                ${i#.} $address $mypeer $nodetype $cb $deltapayblock $coinsleft $lastblock $lastday "$sync"
        else
            printf "%s %s %s %s %s %s %s\n" \
                $address $nodetype $deltapayblock $coinsleft $lastblock $lastday $ip
        fi

    done <<< "$infos"
    address=""
done
