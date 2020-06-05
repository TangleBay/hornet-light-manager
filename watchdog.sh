#!/bin/bash
hornetdir=/var/lib/hornet
hlmcfgdir=/etc/hlm-cfgs
hlmdir=/var/lib/hornet-light-manager
source $hlmcfgdir/hornet.cfg

# Update check
status="$(systemctl show -p ActiveState --value hornet)"
if [ "$status" = "active" ]; then
    if [ "$release" = "stable" ]; then
        latesthornet="$(curl -s https://api.github.com/repos/gohornet/hornet/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"
        latesthornet="${latesthornet:1}"
        nodev="$(curl -s http://127.0.0.1:14265 -X POST -H 'Content-Type: application/json' -H 'X-IOTA-API-Version: 1' -d '{"command": "getNodeInfo"}' | jq '.appVersion')"
        version="${nodev%\"}"
        version="${version#\"}"
        if [ "$version" != "$latesthornet" ]; then
            sudo systemctl stop hornet
            sudo apt update && sudo apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install hornet
            if [ -f "$hornetdir/config.json.dpkg-dist" ]; then
                sudo cp -r $hornetdir/config.json.dpkg-dist $hornetdir/config.json
                sudo rm -rf $hornetdir/config.json.dpkg-dist
            fi
            if [ -f "$hornetdir/config_comnet.json.dpkg-dist" ]; then
                sudo cp -r $hornetdir/config_comnet.json.dpkg-dist $hornetdir/config_comnet.json
                sudo rm -rf $hornetdir/config_comnet.json.dpkg-dist
            fi
            if [ "$neighborport" != "15600" ] || [ "$autopeeringport" != "14626" ]; then
                sudo find $hornetdir/config.json -type f -exec sed -i 's/15600/'$neighborport'/g' {} \;
                sudo find $hornetdir/config.json -type f -exec sed -i 's/14626/'$autopeeringport'/g' {} \;
                sudo find $hornetdir/config_comnet.json -type f -exec sed -i 's/15600/'$neighborport'/g' {} \;
                sudo find $hornetdir/config_comnet.json -type f -exec sed -i 's/14626/'$autopeeringport'/g' {} \;
            fi
            sudo systemctl start hornet
        fi
    fi
    if [ "$release" = "testing" ]; then
        latesthornet="$(curl -s https://api.github.com/repos/gohornet/hornet/releases | grep -oP '"tag_name": "\K(.*)(?=")' | head -n 1)"
        latesthornet="${latesthornet:1}"
        nodev="$(curl -s http://127.0.0.1:14265 -X POST -H 'Content-Type: application/json' -H 'X-IOTA-API-Version: 1' -d '{"command": "getNodeInfo"}' | jq '.appVersion')"
        version="${nodev%\"}"
        version="${version#\"}"
        if [ "$version" != "$latesthornet" ]; then
            sudo systemctl stop hornet
            sudo apt update && sudo apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install hornet
            if [ -f "$hornetdir/config.json.dpkg-dist" ]; then
                sudo cp -r $hornetdir/config.json.dpkg-dist $hornetdir/config.json
                sudo rm -rf $hornetdir/config.json.dpkg-dist
            fi
            if [ -f "$hornetdir/config_comnet.json.dpkg-dist" ]; then
                sudo cp -r $hornetdir/config_comnet.json.dpkg-dist $hornetdir/config_comnet.json
                sudo rm -rf $hornetdir/config_comnet.json.dpkg-dist
            fi
            if [ "$neighborport" != "15600" ] || [ "$autopeeringport" != "14626" ]; then
                sudo find $hornetdir/config.json -type f -exec sed -i 's/15600/'$neighborport'/g' {} \;
                sudo find $hornetdir/config.json -type f -exec sed -i 's/14626/'$autopeeringport'/g' {} \;
                sudo find $hornetdir/config_comnet.json -type f -exec sed -i 's/15600/'$neighborport'/g' {} \;
                sudo find $hornetdir/config_comnet.json -type f -exec sed -i 's/14626/'$autopeeringport'/g' {} \;
            fi
            sudo systemctl start hornet
        fi
    fi
fi

# Service check
if [ "$status" != "active" ]; then
    dt=`date '+%m/%d/%Y %H:%M:%S'`
    sudo systemctl stop hornet
    sudo rm -rf $hornetdir/mainnetdb $hornetdir/export.bin $hornetdir/comnetdb $hornetdir/export_comnet.bin
    sudo systemctl start hornet
    counter="$(cat $hlmdir/log/watchdog.log | sed -n -e '1{p;q}')"
    let counter=counter+1
    {
    echo $counter
    echo $dt
    } > $hlmdir/log/watchdog.log
    counter=0
fi

# Check sync
lmi="$(curl -s http://127.0.0.1:14265 -X POST -H 'Content-Type: application/json' -H 'X-IOTA-API-Version: 1' -d '{"command": "getNodeInfo"}' | jq '.latestMilestoneIndex')"
lsmi="$(curl -s http://127.0.0.1:14265 -X POST -H 'Content-Type: application/json' -H 'X-IOTA-API-Version: 1' -d '{"command": "getNodeInfo"}' | jq '.latestSolidSubtangleMilestoneIndex')"
let dlmi=$lmi-$lsmi
if [ "$status" = "active" ] && [ $dlmi -gt $maxlmi ]; then
    dt=`date '+%m/%d/%Y %H:%M:%S'`
    sudo systemctl stop hornet
    sudo rm -rf $hornetdir/mainnetdb $hornetdir/export.bin $hornetdir/comnetdb $hornetdir/export_comnet.bin
    sudo systemctl start hornet
    counter="$(cat $hlmdir/log/watchdog.log | sed -n -e '1{p;q}')"
    let counter=counter+1
    {
    echo $counter
    echo $dt
    } > $hlmdir/log/watchdog.log
    counter=0
fi

# Log Pruning
if [ "$logpruning" = "true" ]; then
    currentlogsize="$(wc -c $hornetdir/hornet.log | awk '{print $1}')"
    let logsize=$logsize*1000000
    if [ $currentlogsize -gt $logsize ]; then
        echo -n "" > $hornetdir/hornet.log
    fi
fi
exit 0
