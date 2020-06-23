#!/bin/bash
hornetdir=/var/lib/hornet
hlmcfgdir=/etc/hlm-cfgs
hlmdir=/var/lib/hornet-light-manager
source $hlmcfgdir/hornet.cfg
source $hlmcfgdir/watchdog.cfg

# Get Service Status
status="$(systemctl show -p ActiveState --value hornet)"

# Update check
if [ "$autoupdate" = "true" ]; then
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

                # Check neighbor port
                if [ "$neighborport" != "15600" ]; then
                    if [ -n "$neighborport" ]; then
                        sudo jq '.network.gossip.bindAddress = "0.0.0.0:'$neighborport'"' $hornetdir/config.json|sponge $hornetdir/config.json
                        sudo jq '.network.gossip.bindAddress = "0.0.0.0:'$neighborport'"' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    fi
                fi

                # Check autopeering port
                if [ "$autopeeringport" != "14626" ]; then
                    if [ -n "$autopeeringport" ]; then
                        sudo jq '.network.autopeering.bindAddress = "0.0.0.0:'$autopeeringport'"' $hornetdir/config.json|sponge $hornetdir/config.json
                        sudo jq '.network.autopeering.bindAddress = "0.0.0.0:'$autopeeringport'"' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    fi         
                fi

                # Check if pow is enabled
                powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config.json)"
                if [ "$pow" = "true" ] && [ "$powstatus" != "true" ]; then
                    sudo jq '.httpAPI.permitRemoteAccess |= .+ ["attachToTangle"]' $hornetdir/config_comnet.json|sponge $hornetdir/config.json
                fi
                powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config_comnet.json)"
                if [ "$pow" = "true" ] && [ "$powstatus" != "true" ]; then
                    sudo jq '.httpAPI.permitRemoteAccess |= .+ ["attachToTangle"]' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                fi

                # Check if pow is disabled
                powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config.json)"
                if [ "$pow" = "false" ] && [ "$powstatus" != "false" ]; then
                    sudo jq '.httpAPI.permitRemoteAccess |= .- ["attachToTangle"]' $hornetdir/config.json|sponge $hornetdir/config.json
                fi
                powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config_comnet.json)"
                if [ "$pow" = "false" ] && [ "$powstatus" != "false" ]; then
                    sudo jq '.httpAPI.permitRemoteAccess |= .- ["attachToTangle"]' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                fi

                # Check pruning settings
                pruningsetting="$(jq '.snapshots.pruning.enabled' $hornetdir/config.json)"
                if [ "$pruningsetting" != "$pruning" ]; then
                    if [ "$pruning" = "true" ] || [ "$pruning" = "false" ]; then
                        sudo jq '.snapshots.pruning.enabled = '$pruning'' $hornetdir/config.json|sponge $hornetdir/config.json
                    fi
                fi
                pruningsetting="$(jq '.snapshots.pruning.enabled' $hornetdir/config_comnet.json)"
                if [ "$pruningsetting" != "$pruning" ]; then
                    if [ "$pruning" = "true" ] || [ "$pruning" = "false" ]; then
                        sudo jq '.snapshots.pruning.enabled = '$pruning'' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    fi
                fi

                # Check pruning delay settings
                pruningsetting="$(jq '.snapshots.pruning.delay' $hornetdir/config.json)"
                if [ "$pruningsetting" != "$pruningdelay" ]; then
                    if [ -n "$pruningdelay" ]; then
                        sudo jq '.snapshots.pruning.delay = '$pruningdelay'' $hornetdir/config.json|sponge $hornetdir/config.json
                    fi
                fi
                pruningsetting="$(jq '.snapshots.pruning.delay' $hornetdir/config_comnet.json)"
                if [ "$pruningsetting" != "$pruningdelay" ]; then
                    if [ -n "$pruningdelay" ]; then
                        sudo jq '.snapshots.pruning.delay = '$pruningdelay'' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    fi
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

                # Check neighbor port
                if [ "$neighborport" != "15600" ]; then
                    if [ -n "$neighborport" ]; then
                        sudo jq '.network.gossip.bindAddress = "0.0.0.0:'$neighborport'"' $hornetdir/config.json|sponge $hornetdir/config.json
                        sudo jq '.network.gossip.bindAddress = "0.0.0.0:'$neighborport'"' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    fi
                fi

                # Check autopeering port
                if [ "$autopeeringport" != "14626" ]; then
                    if [ -n "$autopeeringport" ]; then
                        sudo jq '.network.autopeering.bindAddress = "0.0.0.0:'$autopeeringport'"' $hornetdir/config.json|sponge $hornetdir/config.json
                        sudo jq '.network.autopeering.bindAddress = "0.0.0.0:'$autopeeringport'"' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    fi         
                fi

                # Check if pow is enabled
                powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config.json)"
                if [ "$pow" = "true" ] && [ "$powstatus" != "true" ]; then
                    sudo jq '.httpAPI.permitRemoteAccess |= .+ ["attachToTangle"]' $hornetdir/config_comnet.json|sponge $hornetdir/config.json
                fi
                powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config_comnet.json)"
                if [ "$pow" = "true" ] && [ "$powstatus" != "true" ]; then
                    sudo jq '.httpAPI.permitRemoteAccess |= .+ ["attachToTangle"]' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                fi

                # Check if pow is disabled
                powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config.json)"
                if [ "$pow" = "false" ] && [ "$powstatus" != "false" ]; then
                    sudo jq '.httpAPI.permitRemoteAccess |= .- ["attachToTangle"]' $hornetdir/config.json|sponge $hornetdir/config.json
                fi
                powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config_comnet.json)"
                if [ "$pow" = "false" ] && [ "$powstatus" != "false" ]; then
                    sudo jq '.httpAPI.permitRemoteAccess |= .- ["attachToTangle"]' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                fi

                # Check pruning settings
                pruningsetting="$(jq '.snapshots.pruning.enabled' $hornetdir/config.json)"
                if [ "$pruningsetting" != "$pruning" ]; then
                    if [ "$pruning" = "true" ] || [ "$pruning" = "false" ]; then
                        sudo jq '.snapshots.pruning.enabled = '$pruning'' $hornetdir/config.json|sponge $hornetdir/config.json
                    fi
                fi
                pruningsetting="$(jq '.snapshots.pruning.enabled' $hornetdir/config_comnet.json)"
                if [ "$pruningsetting" != "$pruning" ]; then
                    if [ "$pruning" = "true" ] || [ "$pruning" = "false" ]; then
                        sudo jq '.snapshots.pruning.enabled = '$pruning'' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    fi
                fi

                # Check pruning delay settings
                pruningsetting="$(jq '.snapshots.pruning.delay' $hornetdir/config.json)"
                if [ "$pruningsetting" != "$pruningdelay" ]; then
                    if [ -n "$pruningdelay" ]; then
                        sudo jq '.snapshots.pruning.delay = '$pruningdelay'' $hornetdir/config.json|sponge $hornetdir/config.json
                    fi
                fi
                pruningsetting="$(jq '.snapshots.pruning.delay' $hornetdir/config_comnet.json)"
                if [ "$pruningsetting" != "$pruningdelay" ]; then
                    if [ -n "$pruningdelay" ]; then
                        sudo jq '.snapshots.pruning.delay = '$pruningdelay'' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    fi
                fi

                sudo systemctl start hornet
            fi
        fi
    fi
fi

# Service check
if [ "$status" != "active" ]; then
    dt=`date '+%m/%d/%Y %H:%M:%S'`
    sudo systemctl restart hornet
    counter="$(cat $hlmdir/log/watchdog.log | sed -n -e '1{p;q}')"
    let counter=counter+1
    {
    echo $counter
    echo $dt
    } > $hlmdir/log/watchdog.log
    counter=0
fi

# Check sync
if [ "$checksync" = "true" ]; then
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
fi

# Log Pruning
if [ "$logpruning" = "true" ]; then
    currentlogsize="$(wc -c $hornetdir/hornet.log | awk '{print $1}')"
    let logsize=$logsize*1000000
    if [ $currentlogsize -gt $logsize ]; then
        echo -n "" > $hornetdir/hornet.log
    fi
fi

# DB Pruning
if [ "$status" != "active" ]; then
    if [ "$pruning" = "true" ]; then
        currentdbsize="$(du -s $hornetdir/ | awk '{print $1}')"
        let dbsize=$maxdbsize*1000000
        if [ $currentdbsize -gt $maxdbsize ]; then

        fi
    fi
fi

exit 0
