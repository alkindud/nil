#!/bin/sh

NODE_USER=sinovate

if [ "$(ps -e | grep sind | wc -l)" -eq "0" ]; then
    /home/$NODE_USER/notifier.sh "$(hostname): infinitynodes not running"
    exit 0
fi

sindirs=$(find /home/$NODE_USER -name '.sin[0-9]' -type d -printf '%f\n' | sort)
for i in $sindirs; do
    isstarted=$(ps ax | grep "[/]$i[/]")
    if [ ! "$isstarted" ]; then
        /home/$NODE_USER/notifier.sh "$(hostname)-${i#.sin}: not started"
    fi
done
