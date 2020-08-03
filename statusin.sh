#!/bin/bash

NODE_USER=sinovate

if [ "$(ps -e | grep sind | wc -l)" -eq "0" ]; then
    echo "Service sind do not started"
    exit 0
fi

sindirs=".sin"
if [ ! "$(ps ax | grep "sind.*[.]sin[/]")" ]; then
    # multinode
    sindirs=$(find /home/$NODE_USER -name '.sin[0-9]' -type d -printf '%f\n' | sort)
fi

address="$1"
if [ "$address" ]; then
    sindirs=".$(ps ax | grep "sind.*[.]sin[0-9]" | grep -o "sin[0-9]" | sort -u | head -n 1)"
fi

for i in $sindirs; do
    isstarted=$(ps ax | grep "[/]$i[/]")
    if [ ! "$isstarted" ]; then
        echo -e "$(hostname)${i#.sin}:\t\e[91mnot started\e[0m"
        continue
    fi
    if [ "$i" = ".sin" ]; then
        cli="/home/$NODE_USER/sin-cli"
    else
        cli="/home/$NODE_USER/${i#.}"
        if ! test -f $cli; then
            echo "Error: $cli not found"
            exit
        fi
    fi

    if [ ! "$address" ]; then
        # vps
        mnstatus=$($cli masternode status 2>/dev/null)
        address=$(echo "$mnstatus" | awk -F "\"" '/payee/{print $4}')
        started=$(echo "$mnstatus" | awk -F "\"" '/status/{print $4}')
        synchronized=$($cli mnsync status 2>/dev/null | awk -F "\"" '/AssetName/{print $4}')
        if [ ! "$address" ]; then
            [ ! "$started" ] && started="Node loading..."
            [ ! "$synchronized" ] && synchronized="no sync"
            echo -e "$(hostname)${i#.sin}:\t\e[93m$started\e[0m, \e[93m$synchronized\e[0m"
            continue
        fi
    fi

    infos=$($cli infinitynode show-infos 2>/dev/null)
    common=$($cli masternodelist full 2>/dev/null | tr -d "\",")
    ennodetypes=$(echo "$common" | grep " ENABLED" | awk '/[0-9]+/{print $12}' | sort -n | uniq -c)
    common=$(echo "$common" | grep "$address")

    currentblock=$($cli getblockcount)
    nodecount=$($cli masternode count all 2>/dev/null | awk '{print "\\e[92m" $4 "\\e[39m"}')

    n=0
    echo "$common" | while read j; do
        [ "$j" ] && address=$(echo "$j" | awk '{print $4}')
        nodeinfo=$(echo "$infos" | grep "\"$address" | wc -l)
#        [ "$nodeinfo" -eq "0" ] && continue
        [ "$nodeinfo" -eq "1" ] && n=1
        # several infinitynodes at the same address
        [ "$nodeinfo" -gt "1" ] && n=$((++n))

        uptime=$(echo "$j" | awk '{print $6}')
        if [ "$uptime" ]; then
            nodeuptime=$(printf "%d days %s" $(( $uptime/60/60/24 )) $(date -u -d @$uptime +%T))
        else
            nodeuptime="unknown"
        fi

        status=$(echo "$j" | awk '{print $2}')
        if [ ! "$status" ]; then
            status="DISABLED"
        fi

        if [[ "$status" == "ENABLED" ]]; then
            status="\e[92m$status\e[0m"
        elif [[ "$status" == "DISABLED" ]]; then
            status="\e[91m$status\e[0m"
        else
            status="\e[93m$status\e[0m"
        fi

        timepayout=$(echo "$j" | awk '{print $7}')
        [ ! "$timepayout" ] && timepayout=0
        if [ "$timepayout" -eq "0" ]; then
            lastpayout="unknown"
        else
            difference=$(( $(date +%s) - $(date -d @$timepayout +%s) ))
            lastpayout=$(printf "%.2d:%s\n" $(( $difference/60/60 )) $(date -d @$difference +%M:%S))
        fi

        firstblock=$(echo "$infos" | grep "\"$address" | head -n$n | tail -n1 | awk '{print $3}')
        if [ ! "$firstblock" ]; then
            outpoint=$(echo "$j" | awk -F ":" '{print $1}' | tr "-" " ")
            if [ "$outpoint" ]; then
                lifetime=$($cli gettxout $outpoint 2>/dev/null | awk -F ":" '/confirmations/{print $2}' | tr -d "\", ")
                lastblock=$(( currentblock - lifetime + 262800 ))
            else
                lifetime=0
                lastblock=0
            fi
        else
            lastblock=$(echo "$infos" | grep "\"$address" | head -n$n | tail -n1 | awk '{print $4}')
            lifetime=$(( $currentblock-$firstblock ))
        fi
        lastday=`date -u -d "+$(( ($lastblock-$currentblock)*2 )) minutes" +%F`

        ip=$(echo "$j" | awk '{print $9}' | awk -F ":" '{print $1}')
        [ ! "$ip" ] && ip="unknown"
        nodetype=$(echo "$infos" | grep "\"$address" | head -n$n | tail -n1 | awk '{print $5}')
        [ ! "$nodetype" ] && nodetype=$(echo "$j" | awk '{print $12}')
        [ ! "$nodetype" ] && nodetype="unknown"
        mynodescount=$(echo "$ennodetypes" | grep "$nodetype$" | awk '{print $1}')
        [ ! "$mynodescount" ] && mynodescount=1

        nr[1]=160; nr[5]=838; nr[10]=1752
        idreward=$(echo "$infos" | grep "\"$address" | head -n$n | tail -n1 | awk '{print $6}')
        if [ "$idreward" ]; then
            reward=${nr[$idreward]}
        else
            reward=$(echo "$j" | awk '{print $11}')
        fi
        [ ! "$reward" ] && reward=0
        coinsleft=$(( (720*365-$lifetime)/$mynodescount*$reward ))
        [ "$coinsleft" -lt "0" ] && coinsleft=0

        # shortening
        nodetype=${nodetype/1000000/big}
        nodetype=${nodetype/500000/mid}
        nodetype=${nodetype/100000/min}
        started=${started/Masternode successfully started/\\e[92mSTARTED\\e[0m}
        synchronized=${synchronized/MASTERNODE_SYNC_FINISHED/\\e[92mSYNC FINISHED\\e[0m}
        lastblock="\e[95m$lastblock\e[0m"
        lastday="\e[95m$lastday\e[0m"
        coinsleft="\e[95m$((coinsleft/1000))k\e[0m"

        if [ "$mnstatus" ]; then
            echo -e "$(hostname)${i#.sin}:\t${address:0:7}, $status, $nodetype, $nodecount, $currentblock, $lastpayout, $coinsleft, $lastblock, $lastday, $started, $synchronized"
        else
            echo -e "$address, $status, $nodetype, $lastpayout, $nodeuptime, $coinsleft, $lastblock, $lastday, $ip"
        fi
    done
    address=""
done
