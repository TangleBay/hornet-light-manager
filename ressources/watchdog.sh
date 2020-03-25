#!/bin/bash
pwdcmd=`dirname "$BASH_SOURCE"`
source $pwdcmd/config.cfg
check="$(systemctl show -p ActiveState --value hornet)"

if [ "$check" = "active" ]; then
    latesthornet="$(curl -s https://api.github.com/repos/gohornet/hornet/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"
    latesthornet="${latesthornet:1}"
    nodev="$(curl -s http://127.0.0.1:14265 -X POST -H 'Content-Type: application/json' -H 'X-IOTA-API-Version: 1' -d '{"command": "getNodeInfo"}' | jq '.appVersion')"
    version="${nodev%\"}"
    version="${version#\"}"
    if [ "$version" != "$latesthornet" ]; then
        sudo systemctl stop hornet
        apt update && sudo apt install -y --force-confnew --only-upgrade hornet 
        sudo systemctl start hornet
    fi
fi

if [ "$check" != "active" ]; then
    dt=`date '+%m/%d/%Y %H:%M:%S'`
    sudo systemctl restart hornet
    counter="$(cat $pwdcmd/../log/watchdog.log | sed -n -e '1{p;q}')"
    let counter=counter+1
    {
    echo $counter
    echo $dt
    } > $pwdcmd/../log/watchdog.log
    counter=0
fi
exit 0
