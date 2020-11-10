#!/bin/sh

NODE_USER=sinovate

delay=$(date -u -d "-1 minute" +%FT%H:%M:)
sindirs=$(find /home/$NODE_USER -maxdepth 1 -name '.sin*' -type d)
for i in $sindirs; do
    test -f $i/debug.log || continue
    idx=$(basename $i)
    hash=$(tail -n 1234 $i/debug.log | grep -P "$delay.*ERROR: AcceptBlockHeader: block.*marked invalid" | awk '{print $5}' | sort -u)
    [ "$hash" ] &&  /home/$NODE_USER/notifier.sh "$(hostname)${idx#.sin} invalid block $hash"
done
