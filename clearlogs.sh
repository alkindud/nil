#!/bin/sh

NODE_USER=sinovate

if [ "$(ps -e | grep sind | wc -l)" -eq "0" ]; then
    exit 0
fi

sindirs=$(find /home/$NODE_USER -name '.sin*' -type d)
for i in $sindirs; do
    test -f $i/debug.log && echo -n > $i/debug.log
done
