#!/bin/sh

explorer="http://sin.ccore.online/ext/getaddress/$1"
curl -m 10 -sL $explorer |\
    tr "}[]" "\n" | grep "MASTERNODE" | tr "\",{}:." " " | awk '$6>0' |\
    awk '
        BEGIN{
            t=systime(); summ=0
        }
        {
            if (NR > 1) summ=summ+(t-$9);
            printf ("%d %.2d:%s\n", $6, int((t-$9)/60/60), strftime("%M:%S", t-$9, 1));
            t=$9
        }
        END{
            printf("%.2d:%s\n", int(summ/(NR-1)/60/60), strftime("%M:%S", summ/(NR-1), 1))
        }'
