#!/bin/bash

############################################################################################################################################################
############################################################################################################################################################
# DO NOT EDIT THE LINES BELOW !!! DO NOT EDIT THE LINES BELOW !!! DO NOT EDIT THE LINES BELOW !!! DO NOT EDIT THE LINES BELOW !!!
############################################################################################################################################################
############################################################################################################################################################

version=0.0.9

############################################################################################################################################################

source /etc/hlm-cfgs/hornet.cfg
source /etc/hlm-cfgs/nginx.cfg
source /etc/hlm-cfgs/swarm.cfg

#pwdcmd=`dirname "$BASH_SOURCE"`

TEXT_RED_B='\e[1;31m'
text_yellow='\e[33m'
text_green='\e[32m'
text_red='\e[31m'
text_reset='\e[0m'

hlmdir="/var/lib/hornet-light-manager"
hlmcfgdir="/etc/hlm-cfgs"
hornetdir="/var/lib/hornet"
hlmgit="https://github.com/TangleBay/hornet-light-manager.git"
hlmcfggit="https://github.com/TangleBay/hlm-cfgs.git"
latesthlm="$(curl -s https://api.github.com/repos/TangleBay/hornet-light-manager/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"
croncmd="$hlmdir/watchdog.sh"
cronjob="*/15 * * * * $croncmd"
swarmtime="$(( ( RANDOM % 55 )  + 5 ))"
croncmdswarm="$hlmdir/auto-swarm.sh"
cronjobswarm="$swarmtime 0 1 * * $croncmdswarm"
envfile=/etc/environment

if [ "$release" = "stable" ]; then
    latesthornet="$(curl -s https://api.github.com/repos/gohornet/hornet/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"
    latesthornet="${latesthornet:1}"
fi
if [ "$release" = "testing" ]; then
    latesthornet="$(curl -s https://api.github.com/repos/gohornet/hornet/releases | grep -oP '"tag_name": "\K(.*)(?=")' | head -n 1)"
    latesthornet="${latesthornet:1}"
fi

############################################################################################################################################################

clear
function pause(){
   read -p "$*"
}


# Check if script is running with root permissions
if [ $(id -u) -ne 0 ]; then
    echo -e $TEXT_RED_B "Please run HLM with sudo or as root"
    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
    echo -e $text_reset
    exit 0
fi

# Check if a package is missing
if ! [ -x "$(command -v curl)" ]; then
    echo -e $text_yellow && echo "Installing necessary packages curl..." && echo -e $text_reset
    sudo apt install curl -y > /dev/null
    clear
fi
if ! [ -x "$(command -v jq)" ]; then
    echo -e $text_yellow && echo "Installing necessary package jq..." && echo -e $text_reset
    sudo apt install jq -y > /dev/null
    clear
fi
if ! [ -x "$(command -v nano)" ]; then
    echo -e $text_yellow && echo "Installing necessary package nano..." && echo -e $text_reset
    sudo apt install nano -y > /dev/null
    clear
fi
if ! [ -x "$(command -v whois)" ]; then
    echo -e $text_yellow && echo "Installing necessary package whois..." && echo -e $text_reset
    sudo apt install whois -y > /dev/null
    clear
fi
if ! [ -x "$(command -v sponge)" ]; then
    echo -e $text_yellow && echo "Installing necessary package moreutils..." && echo -e $text_reset
    sudo apt install moreutils -y > /dev/null
    clear
fi
if ! [ -x "$(command -v snap)" ]; then
    echo -e $text_yellow && echo "Installing necessary package snap..." && echo -e $text_reset
    sudo apt install snapd -y > /dev/null
    clear
fi

# Add snap to enviroment file
if ! grep -q /snap/bin "$envfile"; then
    envpath="$(cat /etc/environment | sed 's/.$//')"
    echo "$envpath:/snap/bin\"" > /etc/environment
fi

# Check if cfgs are up2date
if [ -f "$hlmdir/updater.sh" ]; then
    if [ -x "$hlmdir/updater.sh" ]; then
        bash $hlmdir/updater.sh
    else
        sudo chmod +x $hlmdir/updater.sh
        bash $hlmdir/updater.sh
    fi
fi

#if [ "$version" != "$latesthlm" ]; then
#    echo -e $TEXT_RED_B && echo " New version available (v$latesthlm)! Downloading new version..." && echo -e $text_reset
#    ( cd $pwdcmd ; sudo git pull > /dev/null )
#    ( cd $pwdcmd ; sudo git reset --hard origin/$branch )
#    sudo chmod +x $pwdcmd/hlm.sh $pwdcmd/watchdog.sh
#    sudo nano $pwdcmd/config.cfg
#    ScriptLoc=$(readlink -f "$0")
#    exec "$ScriptLoc"
#    exit 0
#fi

if [ ! -d "$hlmcfgdir" ]; then
    echo -e $text_yellow && echo " No config dir detected...Downloading config files!" && echo -e $text_reset
    ( cd /etc ; sudo git clone $hlmcfggit )
    sudo nano $hlmcfgdir/hornet.cfg
fi

counter=0
while [ $counter -lt 1 ]; do
    clear
    source $hlmcfgdir/hornet.cfg
    source $hlmcfgdir/nginx.cfg
    source $hlmcfgdir/watchdog.cfg
    source $envfile

    if [ ! -f "$hlmcfgdir/swarm.cfg" ]; then
        sudo mv $hlmcfgdir/icnp.cfg $hlmcfgdir/swarm.cfg
    fi
    source $hlmcfgdir/swarm.cfg

    nodetempv="$(curl -s http://127.0.0.1:14265 -X POST -H 'Content-Type: application/json' -H 'X-IOTA-API-Version: 1' -d '{"command": "getNodeInfo"}' | jq '.appVersion')"
    nodev="${nodetempv%\"}"
    nodev="${nodev#\"}"
    sync="$(curl -s http://127.0.0.1:14265 -X POST -H 'Content-Type: application/json' -H 'X-IOTA-API-Version: 1' -d '{"command": "getNodeInfo"}' | jq '.isSynced')"

    if [ -f "$hlmdir/log/watchdog.log" ]; then
        sudo crontab -l | grep -q $hlmdir/watchdog.sh && watchdog=active || watchdog=inactive
        watchdogcount="$(cat $hlmdir/log/watchdog.log | sed -n -e '1{p;q}')"
        watchdogtime="$(cat $hlmdir/log/watchdog.log | sed -n -e '2{p;q}')"
    fi

    if [ -f "$hlmdir/log/swarm.log" ]; then
        sudo crontab -l | grep -q $hlmdir/auto-swarm.sh && swarm=active || swarm=inactive
    fi

    ############################################################################################################################################################

    echo ""
    echo -e $text_yellow "\033[1m\033[4mWelcome to the Hornet lightweight manager! [v$version]\033[0m"
    echo ""
    if [ "$latesthlm" != "$version" ] && [ "$latesthlm" != "" ]; then
        echo -e $text_red "#####################################################"
        echo -e $text_red " New version v$latesthlm available, please update HLM!"
        echo -e $text_red "#####################################################"
        echo ""
    fi
    if [ -n "$nodev" ]; then
        if [ "$nodev" = "$latesthornet" ]; then
            echo -e "$text_yellow Hornet Version:$text_green $nodev"
        else
            echo -e "$text_yellow Hornet Version:$text_red $nodev"
        fi
    else
        echo -e "$text_yellow Hornet Version:$text_red N/A"
    fi
    if [ "$sync" = "true" ] || [ "$sync" = "false" ]; then
        if [ "$sync" = "true" ]; then
            echo -e "$text_yellow Hornet Status:$text_green synced"
        else
            echo -e "$text_yellow Hornet Status:$text_red not synced"
        fi
    else
        echo -e "$text_yellow Hornet Status:$text_red N/A"
    fi
    echo ""
    if [ "$watchdog" = "active" ] || [ "$watchdog" = "inactive" ]; then
        if [ "$watchdog" != "active" ]; then
            echo -e "$text_yellow Watchdog:$text_red $watchdog"
        else
            echo -e "$text_yellow Watchdog:$text_green $watchdog"
            # Autoupdate
            if [ "$autoupdate" = "true" ]; then
                echo -e "$text_yellow Auto-update:$text_green enabled"
            else
                echo -e "$text_yellow Auto-update:$text_red disabled"
            fi
            # Sync Check
            if [ "$checksync" = "true" ]; then
                echo -e "$text_yellow Sync check:$text_green enabled"
            else
                echo -e "$text_yellow Sync check:$text_red disabled"
            fi
            # Log Pruning
            if [ "$logpruning" = "true" ]; then
                echo -e "$text_yellow Log pruning:$text_green enabled"
            else
                echo -e "$text_yellow Log pruning:$text_red disabled"
            fi
            #
            echo -e "$text_yellow WD restarts:$text_red $watchdogcount"
            if [ -n "$watchdogtime" ]; then
                echo -e "$text_yellow Last restart: $watchdogtime"
            fi
        fi
    else
        echo -e "$text_yellow Watchdog:$text_red inactive"
    fi
    if [ "$swarm" = "active" ] || [ "$swarm" = "inactive" ]; then
        if [ "$swarm" = "active" ]; then
            echo ""
            echo -e "$text_yellow Auto-Swarm:$text_green $swarm"
        fi
    fi
    echo ""
    echo -e "\e[90m==========================================================="
    echo ""
    echo -e $text_red "\033[1m\033[4mManagement\033[0m"
    echo ""
    echo -e $text_yellow
    echo " 1) HLM Toolbox"
    echo ""
    echo " 2) Hornet Node"
    echo ""
    echo " 3) Reverse Proxy"
    echo ""
    echo " 4) Project SWARM"
    echo ""
    echo -e "\e[90m-----------------------------------------------------------"
    echo ""
    echo -e $text_yellow "x) Exit"
    echo ""
    echo -e "\e[90m==========================================================="
    echo -e $text_yellow && read -t 60 -p " Please type in your option: " selector
    echo -e $text_reset

    if [ "$selector" = "1" ]; then
        counter1=0
        while [ $counter1 -lt 1 ]; do
            clear
            echo ""
            echo -e $text_red " \033[1m\033[4mHLM Toolbox\033[0m"
            echo -e $text_yellow ""
            echo " 1) Edit Watchdog.cfg"
            echo " 2) Manage Watchdog"
            echo ""
            echo " 3) Update HLM"
            echo ""
            echo -e " \e[90m-----------------------------------------------------------"
            echo ""
            echo -e $text_yellow "x) Back"
            echo ""
            echo -e " \e[90m==========================================================="
            echo -e $text_yellow && read -p " Please type in your option: " selector
            echo -e $text_reset

            # Change watchdog.cfg
            if [ "$selector" = "1" ] ; then
                sudo nano $hlmcfgdir/watchdog.cfg
                echo -e $text_yellow && echo " Edit configuration finished!" && echo -e $text_reset
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi

            if [ "$selector" = "2" ]; then
                echo -e $TEXT_RED_B && read -p " Would you like to (1)enable/(2)disable or (c)ancel hornet watchdog: " selector_watchdog
                echo -e $text_reset
                if [ "$selector_watchdog" = "1" ]; then
                    echo -e $text_yellow && echo " Enable hornet watchdog..." && echo -e $text_reset
                    sudo mkdir -p $hlmdir/log
                    sudo echo "0" > $hlmdir/log/watchdog.log
                    sudo chmod +x $hlmdir/watchdog.sh
                    ( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
                fi
                if [ "$selector_watchdog" = "2" ]; then
                    echo -e $text_yellow && echo " Disable hornet watchdog..." && echo -e $text_reset
                    ( crontab -l | grep -v -F "$croncmd" ) | crontab -
                fi
                echo -e $text_yellow && echo " Hornet watchdog configuration finished!" && echo -e $text_reset
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi

            if [ "$selector" = "3" ]; then
                echo -e $TEXT_RED_B && read -p " Are you sure you want to update HLM (y/N): " selector_hlmreset
                if [ "$selector_hlmreset" = "y" ] || [ "$selector_hlmreset" = "Y" ]; then
                    ( cd $hlmdir ; sudo git pull ) > /dev/null 2>&1
                    ( cd $hlmdir ; sudo git reset --hard origin/master ) > /dev/null 2>&1
                    sudo chmod +x $hlmdir/hlm.sh $hlmdir/watchdog.sh $hlmdir/auto-swarm.sh $hlmdir/updater.sh
                    bash $hlmdir/updater.sh
                    echo ""
                    echo -e $text_red " HLM update successfully!"
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...' && echo -e $text_reset
                    clear
                    #ScriptLoc=$(readlink -f "$0")
                    #exec "$ScriptLoc"
                    exit 0
                fi
            fi

#            if [ "$selector" = "undefined" ]; then
#                echo -e $TEXT_RED_B && read -p " Are you sure you want to reset all HLM configs (y/N): " selector_hlmreset
#                if [ "$selector_hlmreset" = "y" ] || [ "$selector_hlmreset" = "Y" ]; then
#                    ( cd $hlmcfgdir ; sudo git pull ) > /dev/null 2>&1
#                    ( cd $hlmcfgdir ; sudo git reset --hard origin/master ) > /dev/null 2>&1
#                    echo ""
#                    echo -e $text_red " HLM configs reset successfully!"
#                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...' && echo -e $text_reset
#                    clear
#                    exit 0
#                fi
#            fi

            if [ "$selector" = "x" ] || [ "$selector" = "X" ]; then
                counter1=1
            fi
        done
        unset selector
    fi

############################################################################################################################################################

    if [ "$selector" = "2" ] ; then
        counter2=0
        while [ $counter2 -lt 1 ]; do
            clear
            echo ""
            echo -e $text_red "\033[1m\033[4mHornet Node\033[0m"
            echo -e $text_yellow ""
            echo " 1) Edit HLM-Hornet-Config"
            echo " 2) Edit Hornet Config.json"
            echo " 3) Edit Hornet Peering.json"
            echo ""
            echo " 4) Hornet Service (start/stop)"
            echo " 5) Show latest node log"
            echo " 6) Reset database"
            echo ""
            echo " 7) Update Hornet version"
            echo " 8) Install Hornet Node"
            echo " 9) Remove Hornet Node"
            echo ""
            echo -e "\e[90m-----------------------------------------------------------"
            echo ""
            echo -e $text_yellow "x) Back"
            echo ""
            echo -e "\e[90m==========================================================="
            echo -e $text_yellow && read -p " Please type in your option: " selector
            echo -e $text_reset

            # Change HLM-hornet.cfg
            if [ "$selector" = "1" ] ; then
                currentrelease=$release
                currentnetwork=$network
                sudo nano $hlmcfgdir/hornet.cfg
                source $hlmcfgdir/hornet.cfg

                # Write selected release to config
                if [ "$release" = "stable" ]; then
                    sudo sh -c 'echo "deb http://ppa.hornet.zone stable main" > /etc/apt/sources.list.d/hornet.list'
                fi
                if [ "$release" = "testing" ]; then
                    sudo sh -c 'echo "deb http://ppa.hornet.zone stable main" > /etc/apt/sources.list.d/hornet.list'
                    sudo sh -c 'echo "deb http://ppa.hornet.zone testing main" >> /etc/apt/sources.list.d/hornet.list'
                fi

                # Check if release is changed
                if [ "$release" != "$currentrelease" ]; then
                    echo ""
                    echo -e $TEXT_RED_B " Release change detected!!!" && echo -e $text_reset
                    echo ""
                    echo -e $text_yellow && read -p " Would you like to re-install hornet now (y/N): " selector_releasechange
                    echo -e $text_reset
                    if [ "$selector_releasechange" = "y" ] || [ "$selector_releasechange" = "Y" ]; then
                        sudo apt purge hornet -y
                        sudo apt update && sudo apt dist-upgrade -y && sudo apt upgrade -y
                        sudo apt install hornet -y
                        check="$(systemctl show -p ActiveState --value hornet)"
                        if [ "$check" != "active" ]; then
                            sudo systemctl restart hornet
                        fi
                        echo ""
                        echo -e $text_red " Hornet re-installation finished!"
                        echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                        echo -e $text_reset
                    fi
                echo ""
                fi

                # Check if network changed
                if [ "$network" != "$currentnetwork" ]; then
                    echo ""
                    echo -e $TEXT_RED_B " Network change detected!!!" && echo -e $text_reset
                    if [ "$network" = "mainnet" ]; then
                        echo "" > /etc/default/hornet
                    fi
                    if [ "$network" = "comnet" ]; then
                        echo "OPTIONS=\"--config config_comnet --overwriteCooAddress\"" > /etc/default/hornet
                    fi
                    sudo rm -rf $hornetdir/snapshots/mainnet/* $hornetdir/snapshots/comnet/* $hornetdir/export.bin $hornetdir/export_comnet.bin
                    restart=true
                    echo ""
                    echo -e $text_red " Hornet network change finished!"
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                    echo ""
                fi

                # Check if pow is enabled
                powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config.json)"
                if [ "$pow" = "true" ] && [ "$powstatus" != "true" ]; then
                    sudo jq '.httpAPI.permitRemoteAccess |= .+ ["attachToTangle"]' $hornetdir/config.json|sponge $hornetdir/config.json
                    restart=true
                fi
                powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config_comnet.json)"
                if [ "$pow" = "true" ] && [ "$powstatus" != "true" ]; then
                    sudo jq '.httpAPI.permitRemoteAccess |= .+ ["attachToTangle"]' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    restart=true
                fi

                # Check if pow is disabled
                powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config.json)"
                if [ "$pow" = "false" ] && [ "$powstatus" != "false" ]; then
                    sudo jq '.httpAPI.permitRemoteAccess |= .- ["attachToTangle"]' $hornetdir/config.json|sponge $hornetdir/config.json
                    restart=true
                fi
                powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config_comnet.json)"
                if [ "$pow" = "false" ] && [ "$powstatus" != "false" ]; then
                    sudo jq '.httpAPI.permitRemoteAccess |= .- ["attachToTangle"]' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    restart=true
                fi

                # Check pruning settings
                pruningsetting="$(jq '.snapshots.pruning.enabled' $hornetdir/config.json)"
                if [ "$pruningsetting" != "$pruning" ]; then
                    sudo jq '.snapshots.pruning.enabled = '$pruning'' $hornetdir/config.json|sponge $hornetdir/config.json
                    restart=true
                fi
                pruningsetting="$(jq '.snapshots.pruning.enabled' $hornetdir/config_comnet.json)"
                if [ "$pruningsetting" != "$pruning" ]; then
                    sudo jq '.snapshots.pruning.enabled = '$pruning'' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    restart=true
                fi

                # Check pruning delay settings
                pruningsetting="$(jq '.snapshots.pruning.delay' $hornetdir/config.json)"
                if [ "$pruningsetting" != "$pruningdelay" ]; then
                    sudo jq '.snapshots.pruning.delay = '$pruningdelay'' $hornetdir/config.json|sponge $hornetdir/config.json
                    restart=true
                fi
                pruningsetting="$(jq '.snapshots.pruning.delay' $hornetdir/config_comnet.json)"
                if [ "$pruningsetting" != "$pruningdelay" ]; then
                    sudo jq '.snapshots.pruning.delay = '$pruningdelay'' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    restart=true
                fi

                # Check neighbor port
                portsetting="$(jq '.network.gossip.bindAddress' $hornetdir/config.json)"
                if [ "\"0.0.0.0:$neighborport\"" != "$portsetting" ]; then
                    sudo jq '.network.gossip.bindAddress = "0.0.0.0:'$neighborport'"' $hornetdir/config.json|sponge $hornetdir/config.json
                    restart=true
                fi
                portsetting="$(jq '.network.gossip.bindAddress' $hornetdir/config_comnet.json)"
                if [ "\"0.0.0.0:$neighborport\"" != "$portsetting" ]; then
                    sudo jq '.network.gossip.bindAddress = "0.0.0.0:'$neighborport'"' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    restart=true
                fi

                # Check autopeering port
                portsetting="$(jq '.network.autopeering.bindAddress' $hornetdir/config.json)"
                if [ "\"0.0.0.0:$autopeeringport\"" != "$portsetting" ]; then
                    sudo jq '.network.autopeering.bindAddress = "0.0.0.0:'$autopeeringport'"' $hornetdir/config.json|sponge $hornetdir/config.json
                    restart=true
                fi
                portsetting="$(jq '.network.autopeering.bindAddress' $hornetdir/config_comnet.json)"
                if [ "\"0.0.0.0:$autopeeringport\"" != "$portsetting" ]; then
                    sudo jq '.network.autopeering.bindAddress = "0.0.0.0:'$autopeeringport'"' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                    restart=true
                fi

                # check if a restart is required
                if [ "$restart" = "true" ]; then
                    echo ""
                    echo -e $TEXT_RED_B "Hornet configuration changes detected!" && echo -e $text_reset
                    echo ""
                    echo -e $text_yellow && read -p " Would you like to restart hornet now (y/N): " selector_restart
                    echo -e $text_reset
                    if [ "$selector_restart" = "y" ] || [ "$selector_restart" = "Y" ]; then
                        sudo systemctl restart hornet
                    fi
                    restart=false
                fi
                echo -e $text_yellow && echo " Edit configuration finished!" && echo -e $text_reset
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi

            # Edit config.json
            if [ "$selector" = "2" ] ; then
                echo -e $TEXT_RED_B && read -p " Would you like to edit the (1)mainnet or (2) comnet config: " selector
                if [ "$selector" = "1" ]; then
                    sudo nano $hornetdir/config.json
                    echo -e $TEXT_RED_B && read -p " Would you like to restart hornet now (y/N): " restart
                fi
                if [ "$selector" = "2" ]; then
                    sudo nano $hornetdir/config_comnet.json
                    echo -e $TEXT_RED_B && read -p " Would you like to restart hornet now (y/N): " restart
                fi
                if [ "$restart" = "y" ] || [ "$restart" = "y" ]; then
                    sudo systemctl restart hornet
                    echo -e $text_yellow && echo " Hornet node restarted!" && echo -e $text_reset
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
                unset selector
                unset restart
            fi

            # Edit peering.json
            if [ "$selector" = "3" ] ; then
                if [ ! -f "/var/lib/hornet/peering.json" ]; then
                    echo -e $text_yellow && echo " No peering.json found...Downloading config file!" && echo -e $text_reset
                    sudo -u hornet wget -q -O $hornetdir/peering.json https://raw.githubusercontent.com/gohornet/hornet/master/peering.json
                fi
                sudo nano $hornetdir/peering.json
                echo -e $text_yellow && echo " New peering configuration loaded!" && echo -e $text_reset
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi

            if [ "$selector" = "4" ] ; then
                echo -e $TEXT_RED_B && read -p " Would you like to (1)restart/(2)stop/(3)status or (c)ancel: " selector1
                echo -e $text_reset
                if [ "$selector1" = "1" ]; then
                    unset selector1
                    sudo systemctl restart hornet
                    echo -e $text_yellow && echo " Hornet node (re)started!" && echo -e $text_reset
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
                if [ "$selector1" = "2" ]; then
                    unset selector1
                    sudo systemctl stop hornet
                    echo -e $text_yellow " Hornet node stopped!"
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
                if [ "$selector1" = "3" ]; then
                    unset selector1
                    sudo systemctl status hornet
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
            fi

            if [ "$selector" = "5" ] ; then
                sudo journalctl -fu hornet | less -FRSXM
            fi

            if [ "$selector" = "6" ]; then
                echo -e $TEXT_RED_B && read -p " Would you like to delete (1)mainnetdb or (2)comnetdb or (c)ancel: " selector_deletedb
                echo -e $text_reset
                if [ "$selector_deletedb" = "1" ]; then
                    echo -e $TEXT_RED_B && read -p " Are you sure to delete the database (y/N): " selector6
                    echo -e $text_reset
                    if [ "$selector6" = "y" ] || [ "$selector6" = "Y" ]; then
                        sudo systemctl stop hornet
                        if [ -d "$hornetdir/mainnetdb" ]; then
                            sudo rm -rf $hornetdir/mainnetdb
                        fi
                        if [ -f "$hornetdir/export.bin" ]; then
                            sudo rm -rf $hornetdir/export.bin
                        fi
                        sudo systemctl start hornet
                        echo -e $text_yellow && echo " Reset of the database finished and hornet restarted!" && echo -e $text_reset
                        echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                        echo -e $text_reset
                    fi
                fi
                if [ "$selector_deletedb" = "2" ]; then
                    echo -e $TEXT_RED_B && read -p " Are you sure to delete the database (y/N): " selector6
                    echo -e $text_reset
                    if [ "$selector6" = "y" ] || [ "$selector6" = "Y" ]; then
                        sudo systemctl stop hornet
                        if [ -d "$hornetdir/comnetdb" ]; then
                            sudo rm -rf $hornetdir/comnetdb
                        fi
                        if [ -f "$hornetdir/export_comnet.bin" ]; then
                            sudo rm -rf $hornetdir/export_comnet.bin
                        fi
                        sudo systemctl start hornet
                        echo -e $text_yellow && echo " Reset of the database finished and hornet restarted!" && echo -e $text_reset
                        echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                        echo -e $text_reset
                    fi
                fi
            fi

            if [ "$selector" = "7" ] ; then
                if [ -n "$nodev" ]; then
                    echo -e $text_yellow " Checking if a new version is available..."
                    if [ "$release" = "stable" ]; then
                        latesthornet="$(curl -s https://api.github.com/repos/gohornet/hornet/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"
                        latesthornet="${latesthornet:1}"
                    fi
                    if [ "$release" = "testing" ]; then
                        latesthornet="$(curl -s https://api.github.com/repos/gohornet/hornet/releases | grep -oP '"tag_name": "\K(.*)(?=")' | head -n 1)"
                        latesthornet="${latesthornet:1}"
                    fi
                    if [ "$nodev" = "$latesthornet" ]; then
                        echo -e "$text_green Already up to date."
                    else
                        echo -e $text_red " New Hornet version found... $text_red(v$latesthornet)"
                        echo -e $text_yellow " Stopping Hornet node...(Please note that this may take some time)"
                        sudo systemctl stop hornet
                        echo -e $text_yellow " Updating Hornet..."
                        sudo apt update && sudo apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install hornet

                        # Check if a new config exist after updating
                        if [ -f "$hornetdir/config.json.dpkg-dist" ]; then
                            sudo cp -r $hornetdir/config.json.dpkg-dist $hornetdir/config.json
                            sudo rm -rf $hornetdir/config.json.dpkg-dist
                        fi
                        if [ -f "$hornetdir/config_comnet.json.dpkg-dist" ]; then
                            sudo cp -r $hornetdir/config_comnet.json.dpkg-dist $hornetdir/config_comnet.json
                            sudo rm -rf $hornetdir/config_comnet.json.dpkg-dist
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
                            sudo jq '.httpAPI.permitRemoteAccess |= .- ["attachToTangle"]' $hornetdir/config_comnet.json|sponge $hornetdir/config.json
                        fi
                        powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config_comnet.json)"
                        if [ "$pow" = "false" ] && [ "$powstatus" != "false" ]; then
                            sudo jq '.httpAPI.permitRemoteAccess |= .- ["attachToTangle"]' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                        fi

                        # Check pruning settings
                        pruningsetting="$(jq '.snapshots.pruning.enabled' $hornetdir/config.json)"
                        if [ "$pruningsetting" != "$pruning" ]; then
                            sudo jq '.snapshots.pruning.enabled = '$pruning'' $hornetdir/config.json|sponge $hornetdir/config.json
                        fi
                        pruningsetting="$(jq '.snapshots.pruning.enabled' $hornetdir/config_comnet.json)"
                        if [ "$pruningsetting" != "$pruning" ]; then
                            sudo jq '.snapshots.pruning.enabled = '$pruning'' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                        fi

                        # Check pruning delay settings
                        pruningsetting="$(jq '.snapshots.pruning.delay' $hornetdir/config.json)"
                        if [ "$pruningsetting" != "$pruningdelay" ]; then
                            sudo jq '.snapshots.pruning.delay = '$pruningdelay'' $hornetdir/config.json|sponge $hornetdir/config.json
                        fi
                        pruningsetting="$(jq '.snapshots.pruning.delay' $hornetdir/config_comnet.json)"
                        if [ "$pruningsetting" != "$pruningdelay" ]; then
                            sudo jq '.snapshots.pruning.delay = '$pruningdelay'' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                        fi

                        # Check neighbor port
                        portsetting="$(jq '.network.gossip.bindAddress' $hornetdir/config.json)"
                        if [ "\"0.0.0.0:$neighborport\"" != "$portsetting" ]; then
                            sudo jq '.network.gossip.bindAddress = "0.0.0.0:'$neighborport'"' $hornetdir/config.json|sponge $hornetdir/config.json
                            restart=true
                        fi
                        portsetting="$(jq '.network.gossip.bindAddress' $hornetdir/config_comnet.json)"
                        if [ "\"0.0.0.0:$neighborport\"" != "$portsetting" ]; then
                            sudo jq '.network.gossip.bindAddress = "0.0.0.0:'$neighborport'"' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                            restart=true
                        fi

                        # Check autopeering port
                        portsetting="$(jq '.network.autopeering.bindAddress' $hornetdir/config.json)"
                        if [ "\"0.0.0.0:$autopeeringport\"" != "$portsetting" ]; then
                            sudo jq '.network.autopeering.bindAddress = "0.0.0.0:'$autopeeringport'"' $hornetdir/config.json|sponge $hornetdir/config.json
                            restart=true
                        fi
                        portsetting="$(jq '.network.autopeering.bindAddress' $hornetdir/config_comnet.json)"
                        if [ "\"0.0.0.0:$autopeeringport\"" != "$portsetting" ]; then
                            sudo jq '.network.autopeering.bindAddress = "0.0.0.0:'$autopeeringport'"' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                            restart=true
                        fi

                        echo -e $text_yellow " Starting Hornet node..."
                        sudo systemctl start hornet
                        echo -e $text_yellow " Updating Hornet version finished!"
                        echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                        echo -e $text_reset
                    fi
                else
                    echo -e "$text_red Error! Please try again later."
                fi
            fi

            if [ "$selector" = "8" ]; then
                if [ ! -f "/usr/bin/hornet" ]; then
                    source $hlmcfgdir/hornet.cfg
                    sudo snap install --classic --channel=1.14/stable go
                    sudo wget -qO - https://ppa.hornet.zone/pubkey.txt | sudo apt-key add -
                    if [ "$release" = "stable" ]; then
                        sudo sh -c 'echo "deb http://ppa.hornet.zone stable main" > /etc/apt/sources.list.d/hornet.list'
                    fi
                    if [ "$release" = "testing" ]; then
                        sudo sh -c 'echo "deb http://ppa.hornet.zone stable main" > /etc/apt/sources.list.d/hornet.list'
                        sudo sh -c 'echo "deb http://ppa.hornet.zone testing main" >> /etc/apt/sources.list.d/hornet.list'
                    fi
                    sudo apt update && sudo apt dist-upgrade -y && sudo apt upgrade -y
                    sudo apt install hornet -y

                    # Check which network
                    if [ "$network" = "mainnet" ]; then
                        echo "" > /etc/default/hornet
                        sudo rm -rf $hornetdir/snapshots/mainnet/* $hornetdir/snapshots/comnet/* $hornetdir/export.bin $hornetdir/export_comnet.bin
                        sudo rm -rf $hornetdir/snapshots/mainnet/* $hornetdir/snapshots/comnet/* $hornetdir/export.bin $hornetdir/export_comnet.bin
                        restart=true
                    fi
                    if [ "$network" = "comnet" ]; then
                        echo "OPTIONS=\"--config config_comnet --overwriteCooAddress\"" > /etc/default/hornet
                        sudo rm -rf $hornetdir/snapshots/mainnet/* $hornetdir/snapshots/comnet/* $hornetdir/export.bin $hornetdir/export_comnet.bin
                        sudo rm -rf $hornetdir/snapshots/mainnet/* $hornetdir/snapshots/comnet/* $hornetdir/export.bin $hornetdir/export_comnet.bin
                        restart=true
                    fi

                    # Check if pow is enabled
                    powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config.json)"
                    if [ "$pow" = "true" ] && [ "$powstatus" != "true" ]; then
                        sudo jq '.httpAPI.permitRemoteAccess |= .+ ["attachToTangle"]' $hornetdir/config_comnet.json|sponge $hornetdir/config.json
                        restart=true
                    fi
                    powstatus="$(jq '.httpAPI.permitRemoteAccess | contains(["attachToTangle"])' $hornetdir/config_comnet.json)"
                    if [ "$pow" = "true" ] && [ "$powstatus" != "true" ]; then
                         sudo jq '.httpAPI.permitRemoteAccess |= .+ ["attachToTangle"]' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                         restart=true
                    fi

                    # Check pruning settings
                    pruningsetting="$(jq '.snapshots.pruning.enabled' $hornetdir/config.json)"
                    if [ "$pruningsetting" != "$pruning" ]; then
                        sudo jq '.snapshots.pruning.enabled = '$pruning'' $hornetdir/config.json|sponge $hornetdir/config.json
                        restart=true
                    fi
                    pruningsetting="$(jq '.snapshots.pruning.enabled' $hornetdir/config_comnet.json)"
                    if [ "$pruningsetting" != "$pruning" ]; then
                        sudo jq '.snapshots.pruning.enabled = '$pruning'' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                        restart=true
                    fi

                    # Check pruning delay settings
                    pruningsetting="$(jq '.snapshots.pruning.delay' $hornetdir/config.json)"
                    if [ "$pruningsetting" != "$pruningdelay" ]; then
                        sudo jq '.snapshots.pruning.delay = '$pruningdelay'' $hornetdir/config.json|sponge $hornetdir/config.json
                        restart=true
                    fi
                    pruningsetting="$(jq '.snapshots.pruning.delay' $hornetdir/config_comnet.json)"
                    if [ "$pruningsetting" != "$pruningdelay" ]; then
                        sudo jq '.snapshots.pruning.delay = '$pruningdelay'' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                        restart=true
                    fi

                    # Check neighbor port
                    portsetting="$(jq '.network.gossip.bindAddress' $hornetdir/config.json)"
                    if [ "\"0.0.0.0:$neighborport\"" != "$portsetting" ]; then
                        sudo jq '.network.gossip.bindAddress = "0.0.0.0:'$neighborport'"' $hornetdir/config.json|sponge $hornetdir/config.json
                        restart=true
                    fi
                    portsetting="$(jq '.network.gossip.bindAddress' $hornetdir/config_comnet.json)"
                    if [ "\"0.0.0.0:$neighborport\"" != "$portsetting" ]; then
                        sudo jq '.network.gossip.bindAddress = "0.0.0.0:'$neighborport'"' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                        restart=true
                    fi

                    # Check autopeering port
                    portsetting="$(jq '.network.autopeering.bindAddress' $hornetdir/config.json)"
                    if [ "\"0.0.0.0:$autopeeringport\"" != "$portsetting" ]; then
                        sudo jq '.network.autopeering.bindAddress = "0.0.0.0:'$autopeeringport'"' $hornetdir/config.json|sponge $hornetdir/config.json
                        restart=true
                    fi
                    portsetting="$(jq '.network.autopeering.bindAddress' $hornetdir/config_comnet.json)"
                    if [ "\"0.0.0.0:$autopeeringport\"" != "$portsetting" ]; then
                        sudo jq '.network.autopeering.bindAddress = "0.0.0.0:'$autopeeringport'"' $hornetdir/config_comnet.json|sponge $hornetdir/config_comnet.json
                        restart=true
                    fi

                    if [ -f /usr/bin/hornet ]; then
                        check="$(systemctl show -p ActiveState --value hornet)"
                        if [ "$check" != "active" ]; then
                            sudo systemctl restart hornet
                        fi
                        if [ "$restart" = "true" ]; then
                            sudo systemctl restart hornet
                            restart=false
                        fi
                        echo ""
                        echo -e $TEXT_RED_B
                        echo " You need to open the following ports in your home router for peering"
                        echo " Ports: $autopeeringport/UDP & $neighborport/tcp"
                        echo ""
                        echo -e $text_yellow
                        echo " Hornet installation finished!"
                    else
                        echo -e $TEXT_RED_B ""
                        echo " Error while installing Hornet. Please check hornet.cfg and try again!"
                        echo ""
                    fi
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...' && echo -e $text_reset
                else
                    echo -e $text_red " Hornet already installed. Please remove first!"
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...' && echo -e $text_reset
                fi
            fi

            if [ "$selector" = "9" ]; then
                echo -e $TEXT_RED_B && read -p " Are you sure you want to remove Hornet (y/N): " selector_hornetremove
                echo -e $text_reset
                if [ "$selector_hornetremove" = "y" ] || [ "$selector_hornetremove" = "Y" ]; then
                    ( crontab -l | grep -v -F "$croncmd" ) | crontab -
                    ( crontab -l | grep -v -F "$croncmdswarm" ) | crontab -
                    sudo systemctl stop hornet
                    sudo apt purge hornet -y
                    echo -e $text_red " Hornet was successfully removed!"
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
            fi

            if [ "$selector" = "x" ] || [ "$selector" = "X" ]; then
                counter2=1
            fi
        done
        unset selector
    fi

############################################################################################################################################################

    if [ "$selector" = "3" ]; then
        counter3=0
        while [ $counter3 -lt 1 ]; do
            clear
            echo ""
            echo -e $text_red "\033[1m\033[4mReverse Proxy\033[0m"
            echo -e $text_yellow ""
            echo " 1) Edit Nginx.cfg"
            echo " 2) Update Dashboard Login"
            echo ""
            echo " 3) Deploy reverse proxy"
            echo " 4) Renew SSL Certificate"
            echo ""
            echo -e "\e[90m-----------------------------------------------------------"
            echo ""
            echo -e $text_yellow "x) Back"
            echo ""
            echo -e "\e[90m==========================================================="
            echo -e $text_yellow && read -p " Please type in your option: " selector
            echo -e $text_reset

            # Change nginx.cfg
            if [ "$selector" = "1" ] ; then
                sudo nano $hlmcfgdir/nginx.cfg
                source $hlmcfgdir/nginx.cfg
                echo -e $text_yellow && echo " Edit configuration finished!" && echo -e $text_reset
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi

            # Update Dashboard Login
            if [ "$selector" = "2" ]; then
                if [ -f "/etc/nginx/.htpasswd" ]; then
                    dashpw="$(mkpasswd -m sha-512 $dashpw)"
                    echo "$dashuser:$dashpw" > /etc/nginx/.htpasswd
                    sudo systemctl reload nginx
                    echo -e $text_yellow && echo " Hornet Dashboard login updated!" && echo -e $text_reset
                else
                    echo -e $text_red " Please install nginx first!"
                fi
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi

            if [ "$selector" = "3" ]; then
                if [ ! -f "/etc/nginx/.htpasswd" ]; then
                    dashpw="$(mkpasswd -m sha-512 $dashpw)"
                    sudo echo "$dashuser:$dashpw" > /etc/nginx/.htpasswd
                fi

                if [ ! -d "/etc/letsencrypt" ]; then
                    echo -e $text_yellow && echo " Installing necessary packages..." && echo -e $text_reset
                    sudo apt install software-properties-common certbot python3-certbot-nginx -y
                    rm -rf /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
                    sudo cp $hlmdir/pre-nginx.template /etc/nginx/sites-enabled/default
                    sudo find /etc/nginx/sites-enabled/default -type f -exec sed -i 's/domain.tld/'$domain'/g' {} \;
                    sudo systemctl restart nginx

                    dashpw="$(mkpasswd -m sha-512 $dashpw)"
                    sudo echo "$dashuser:$dashpw" > /etc/nginx/.htpasswd
                fi

                if [ ! -d "/etc/letsencrypt/live/$domain" ]; then
                    echo -e $text_yellow && echo " Starting SSL-Certificate installation..." && echo -e $text_reset
                    sudo certbot --nginx -d $domain
                    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
                        echo -e $text_yellow && echo " SSL certificate installed!" && echo -e $text_reset
                    else
                        echo -e $text_red " Error! SSL Certificate not found!"
                    fi
                fi

                if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
                    echo -e $text_yellow && echo " Copying Nginx configuration..." && echo -e $text_reset
                    rm -rf /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
                    sudo cp $hlmdir/nginx.template /etc/nginx/sites-enabled/default
                    sudo find /etc/nginx/sites-enabled/default -type f -exec sed -i 's/domain.tld/'$domain'/g' {} \;
                    sudo find /etc/nginx/sites-enabled/default -type f -exec sed -i 's/443/'$nodeport'/g' {} \;
                    sudo find /etc/nginx/sites-enabled/default -type f -exec sed -i 's/\#NGINX/''/g' {} \;
                    sudo systemctl restart nginx
                    echo -e $text_yellow && echo " Nginx configurationen updated!" && echo -e $text_reset
                fi
                echo -e $text_yellow && echo " Reverse proxy configuration finished!" && echo -e $text_reset
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi

            if [ "$selector" = "4" ]; then
                if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
                    sudo certbot renew
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                else
                    echo -e $text_red " Error! No SSL Certificate installed!"
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
            fi

            if [ "$selector" = "x" ] || [ "$selector" = "X" ]; then
                counter3=1
            fi
        done
        unset selector
    fi

############################################################################################################################################################

    if [ "$selector" = "4" ]; then
        counter4=0
        while [ $counter4 -lt 1 ]; do
            clear
            echo ""
            echo -e $text_red "\033[1m\033[4mProject SWARM\033[0m"
            echo ""
            echo -e $text_yellow " SWARM: https://tanglebay.org/swarm"
            #echo -e $text_yellow " Donate: https://pool.einfachiota.de/donate"
            echo -e $text_yellow ""
            echo " 1) Edit SWARM.cfg"
            echo ""
            echo " 2) Add your node to SWARM"
            echo " 3) Remove your node from SWARM"
            echo " 4) Update node on SWARM"
            echo ""
            echo " 5) Manage SWARM auto-adding"
            echo " 6) Show SWARM.log"
            echo ""
            echo -e "\e[90m-----------------------------------------------------------"
            echo ""
            echo -e $text_yellow "x) Back"
            echo ""
            echo -e " \e[90m==========================================================="
            echo -e $text_yellow && read -p " Please type in your option: " selector
            echo -e $text_reset

            # Change swarm.cfg
            if [ "$selector" = "1" ] ; then
                if [ -f "$hlmcfgdir/swarm.cfg" ]; then
                    sudo nano $hlmcfgdir/swarm.cfg
                    source $hlmcfgdir/swarm.cfg
                    echo -e $text_yellow && echo " Edit configuration finished!" && echo -e $text_reset
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
                if [ -f "$hlmcfgdir/icnp.cfg" ]; then
                    sudo mv $hlmcfgdir/icnp.cfg $hlmcfgdir/swarm.cfg
                    sudo nano $hlmcfgdir/swarm.cfg
                    source $hlmcfgdir/swarm.cfg
                    echo -e $text_yellow && echo " Edit configuration finished!" && echo -e $text_reset
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
            fi

            if [ "$selector" = "2" ]; then
                if [ ! -d "$hlmdir/log" ]; then
                    sudo mkdir -p $hlmdir/log
                fi
                if [ ! -f "$hlmdir/log/swarm.log" ]; then
                    sudo touch $hlmdir/log/swarm.log
                fi
                (curl --silent -X POST "https://register.tanglebay.org" -H  "accept: */*" -H  "Content-Type: application/json" -d "{ \"name\": \"$nodename\", \"url\": \"https://$domain:$nodeport/api\", \"address\": \"$donationaddress\", \"pow\": \"$pownode\" }" |jq '.') > $hlmdir/log/swarm.log
                swarmpwd="$(sudo cat $hlmdir/log/swarm.log |jq '.password')"
                if [ -n "$swarmpwd" ]; then
                    sudo sed -i 's/nodepassword.*/nodepassword='$swarmpwd'/' $hlmcfgdir/swarm.cfg
                fi
                sleep 1
                sudo cat $hlmdir/log/swarm.log |jq
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi
            if [ "$selector" = "3" ]; then
                curl --silent -X DELETE https://register.tanglebay.org/$nodepassword |jq
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi
            if [ "$selector" = "4" ]; then
                echo -e $text_red " A node should only be updated in an emergency, as it can lead to the total loss of the current points!"
                echo -e $text_yellow && read -p " Are you sure that you want to update your node (y/N): " selector_swarm_update
                echo -e $text_reset
                if [ "$selector_swarm_update" = "y" ] || [ "$selector_swarm_update" = "Y" ]; then
                    curl --silent --output /dev/null -X DELETE https://register.tanglebay.org/$nodepassword
                    curl --silent -X POST "https://register.tanglebay.org" -H  "accept: */*" -H  "Content-Type: application/json" -d "{ \"name\": \"$nodename\", \"url\": \"https://$domain:$nodeport/api\", \"address\": \"$donationaddress\", \"pow\": \"$pownode\", \"password\": \"$nodepassword\" }" |jq
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
            fi

            if [ "$selector" = "5" ]; then
                echo -e $TEXT_RED_B && read -p " Would you like to (1)enable/(2)disable or (c)ancel SWARM Auto-Season: " selector_autoswarm
                echo -e $text_reset
                if [ "$selector_autoswarm" = "1" ]; then
                    echo -e $text_yellow && echo " Enable SWARM Auto-Season..." && echo -e $text_reset
                    sudo chmod +x $hlmdir/auto-swarm.sh
                    ( crontab -l | grep -v -F "$croncmdswarm" ; echo "$cronjobswarm" ) | crontab -
                fi
                if [ "$selector_autoswarm" = "2" ]; then
                    echo -e $text_yellow && echo " Disable SWARM Auto-Season..." && echo -e $text_reset
                    ( crontab -l | grep -v -F "$croncmdswarm" ) | crontab -
                fi
                echo -e $text_yellow && echo " SWARM Auto-Season configuration finished!" && echo -e $text_reset
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi

            if [ "$selector" = "6" ]; then
                if [ -f "$hlmdir/log/swarm.log" ]; then
                    sudo cat $hlmdir/log/swarm.log |jq
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                else
                    echo -e $text_red " No SWARM.log found!"
                    echo ""
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
            fi

            if [ "$selector" = "x" ] || [ "$selector" = "X" ]; then
                counter4=1
            fi
        done
        unset selector
    fi

############################################################################################################################################################

    if [ "$selector" = "x" ] || [ "$selector" = "X" ]; then
        counter=1
    fi
done
counter=0
clear
exit 0