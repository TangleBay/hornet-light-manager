#!/bin/bash

############################################################################################################################################################
############################################################################################################################################################
# DO NOT EDIT THE LINES BELOW !!! DO NOT EDIT THE LINES BELOW !!! DO NOT EDIT THE LINES BELOW !!! DO NOT EDIT THE LINES BELOW !!!
############################################################################################################################################################
############################################################################################################################################################

version=0.0.1

############################################################################################################################################################

source /etc/hlm-cfgs/hornet.cfg

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
swarmtime="$(( ( RANDOM % 60 )  + 5 ))"
croncmdswarm="$hlmdir/auto-swarm.sh"
cronjobswarm="$swarmtime 0 1 * * $croncmdswarm"

if [ "$release" = "stable" ]; then
    latesthornet="$(curl -s https://api.github.com/repos/gohornet/hornet/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"
    latesthornet="${latesthornet:1}"
fi
if [ "$release" = "testing" ]; then
    latesthornet="$(curl -s https://api.github.com/repos/gohornet/hornet/releases | grep -oP '"tag_name": "\K(.*)(?=")' | head -n 1)"
    latesthornet="${latesthornet:1}"
fi

if [ "$latesthlm" != "$version" ]; then
    up2date=$text_red"v"$version
else
    up2date=$text_green"v"$version
fi

############################################################################################################################################################

clear
function pause(){
   read -p "$*"
}

if [ $(id -u) -ne 0 ]; then
    echo -e $TEXT_RED_B "Please run HLM with sudo or as root"
    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
    echo -e $text_reset
    exit 0
fi

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
if ! [ -x "$(command -v snap)" ]; then
    echo -e $text_yellow && echo "Installing necessary package snap..." && echo -e $text_reset
    sudo apt install snapd -y > /dev/null
    envfile=/etc/environment
    if ! grep -q /snap/bin "$envfile"; then
        envpath="$(cat /etc/environment | sed 's/.$//')"
        echo "$envpath:/snap/bin\"" > /etc/environment
        echo -e $text_red " Packages successfully installed! System needs to be rebooted..."
        echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
        echo -e $text_reset
        sudo reboot
    fi
    clear
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

    ############################################################################################################################################################

    echo ""
    echo -e $text_yellow "\033[1m\033[4mWelcome to the Hornet lightweight manager! [$up2date$text_yellow]\033[0m"
    echo ""
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
            echo -e "$text_yellow Restarts:$text_red $watchdogcount"
            if [ -n "$watchdogtime" ]; then
                echo -e "$text_yellow Last restart: $watchdogtime"
            fi
        fi
    else
        echo -e "$text_yellow Watchdog:$text_red inactive"
    fi
    echo ""
    echo -e "\e[90m==========================================================="
    echo ""
    echo -e $text_red "\033[1m\033[4mManagement\033[0m"
    echo ""
    echo -e $text_yellow
    echo " 1) HLM Tools"
    echo ""
    echo " 2) Hornet Management"
    echo ""
    echo " 3) Project SWARM"
    echo ""
    echo " 4) Edit Configurations"
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
            echo -e $text_red " \033[1m\033[4mHLM Tools\033[0m"
            echo -e $text_yellow ""
            echo " 1) Install Hornet"
            echo " 2) Remove Hornet"
            echo ""
            echo " 3) Install HTTPS proxy"
            echo " 4) Manage Watchdog"
            echo ""
            echo " 5) Update Hornet-Light-Manager"
            echo " 6) Reset all HLM configs"
            echo ""
            echo -e " \e[90m-----------------------------------------------------------"
            echo ""
            echo -e $text_yellow "x) Back"
            echo ""
            echo -e " \e[90m==========================================================="
            echo -e $text_yellow && read -p " Please type in your option: " selector
            echo -e $text_reset
            if [ "$selector" = "1" ]; then
                if [ ! -f "/usr/bin/hornet" ]; then
                    sudo snap install --classic --channel=1.14/stable go
                    sudo wget -qO - https://ppa.hornet.zone/pubkey.txt | sudo apt-key add -
                    sudo sh -c 'echo "deb http://ppa.hornet.zone '$release' main" > /etc/apt/sources.list.d/hornet.list'
                    sudo apt update && sudo apt dist-upgrade -y && sudo apt upgrade -y
                    sudo apt install hornet -y
                    if [ -f /usr/bin/hornet ]; then
                        check="$(systemctl show -p ActiveState --value hornet)"
                        if [ "$check" != "active" ]; then
                            sudo systemctl restart hornet
                        fi
                        echo ""
                        echo -e $TEXT_RED_B
                        echo " You need to open the following ports in your home router for peering"
                        echo " Ports: 14626/UDP & 15600/tcp"
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

            if [ "$selector" = "2" ]; then
                echo -e $TEXT_RED_B && read -p " Are you sure you want to remove Hornet (y/N): " selector_hornetremove
                echo -e $text_reset
                if [ "$selector_hornetremove" = "y" ] || [ "$selector_hornetremove" = "Y" ]; then
                    ( crontab -l | grep -v -F "$croncmd" ) | crontab -
                    sudo systemctl stop hornet
                    sudo apt purge hornet -y
                    echo -e $text_red " Hornet was successfully removed!"
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
            fi

            if [ "$selector" = "3" ]; then
                echo -e $text_yellow && echo " Installing necessary packages..." && echo -e $text_reset
                sudo apt install software-properties-common nginx -y
                sudo snap install --beta --classic certbot
                #certbot="certbot/certbot"
                #if ! grep -q "^deb .*$certbot" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
                #    sudo add-apt-repository ppa:certbot/certbot -y
                #fi
                #sudo apt update && sudo apt install python-certbot-nginx -y

                if [ "$nginxservice" = "repair" ]; then
                    sudo mkdir /etc/systemd/system/nginx.service.d
                    sudo printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
                    sudo systemctl daemon-reload
                fi

                echo -e $text_yellow && echo " Copying Nginx configuration..." && echo -e $text_reset
                rm -rf /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
                sudo cp $hlmdir/nginx.template /etc/nginx/sites-enabled/default
                sudo find /etc/nginx/sites-enabled/default -type f -exec sed -i 's/domain.tld/'$domain'/g' {} \;
                sudo find /etc/nginx/sites-enabled/default -type f -exec sed -i 's/14266/'$apiport'/g' {} \;
                sudo find /etc/nginx/sites-enabled/default -type f -exec sed -i 's/14267/'$dashport'/g' {} \;
                sudo find /etc/nginx/nginx.conf -type f -exec sed -i 's/\# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/g' {} \;
                dashpw="$(mkpasswd -m sha-512 $dashpw)"
                sudo echo "$dashuser:$dashpw" > /etc/nginx/.htpasswd
                sudo systemctl restart nginx

                echo -e $text_yellow && echo " Starting SSL-Certificate installation..." && echo -e $text_reset
                sudo certbot certonly --nginx -d $domain

                if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
                    sudo cp $hlmdir/nginx.template /etc/nginx/sites-enabled/default
                    sudo find /etc/nginx/sites-enabled/default -type f -exec sed -i 's/domain.tld/'$domain'/g' {} \;
                    sudo find /etc/nginx/sites-enabled/default -type f -exec sed -i 's/14266/'$apiport'/g' {} \;
                    sudo find /etc/nginx/sites-enabled/default -type f -exec sed -i 's/14267/'$dashport'/g' {} \;
                    sudo find /etc/nginx/sites-enabled/default -type f -exec sed -i 's/\#NGINX/''/g' {} \;
                    sudo systemctl restart nginx
                    echo -e $text_yellow && echo " SSL Certificate installed!" && echo -e $text_reset
                else
                    echo -e $text_red " Error! SSL Certificate not found!"
                fi
                echo -e $text_yellow && echo " Reverse proxy installation finished!" && echo -e $text_reset
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi

            if [ "$selector" = "4" ]; then
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

            if [ "$selector" = "5" ]; then
                echo -e $TEXT_RED_B && read -p " Are you sure you want to update HLM (y/N): " selector_hlmreset
                if [ "$selector_hlmreset" = "y" ] || [ "$selector_hlmreset" = "Y" ]; then
                    ( cd $hlmdir ; sudo git pull ) > /dev/null 2>&1
                    ( cd $hlmdir ; sudo git reset --hard origin/master ) > /dev/null 2>&1
                    sudo chmod +x $hlmdir/hlm.sh $hlmdir/watchdog.sh $hlmdir/auto-swarm.sh
                    echo ""
                    echo -e $text_red " HLM update successfully!"
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...' && echo -e $text_reset
                    clear
                    #ScriptLoc=$(readlink -f "$0")
                    #exec "$ScriptLoc"
                    exit 0
                fi
            fi

            if [ "$selector" = "6" ]; then
                echo -e $TEXT_RED_B && read -p " Are you sure you want to reset all HLM configs (y/N): " selector_hlmreset
                if [ "$selector_hlmreset" = "y" ] || [ "$selector_hlmreset" = "Y" ]; then
                    ( cd $hlmcfgdir ; sudo git pull ) > /dev/null 2>&1
                    ( cd $hlmcfgdir ; sudo git reset --hard origin/master ) > /dev/null 2>&1
                    echo ""
                    echo -e $text_red " HLM configs reset successfully!"
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...' && echo -e $text_reset
                    ScriptLoc=$(readlink -f "$0")
                    exec "$ScriptLoc"
                    exit 0
                fi
            fi

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
            echo -e $text_red "\033[1m\033[4mHornet Management\033[0m"
            echo -e $text_yellow ""
            echo " 1) Control Hornet (start/stop)"
            echo " 2) Show latest node log"
            echo " 3) Reset database"
            echo ""
            echo " 4) Update Dashboard login"
            echo " 5) Update Hornet version"
            echo ""
            echo -e "\e[90m-----------------------------------------------------------"
            echo ""
            echo -e $text_yellow "x) Back"
            echo ""
            echo -e "\e[90m==========================================================="
            echo -e $text_yellow && read -p " Please type in your option: " selector
            echo -e $text_reset
            if [ "$selector" = "1" ] ; then
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

            if [ "$selector" = "2" ] ; then
                sudo journalctl -fu hornet | less -FRSXM
            fi

            if [ "$selector" = "3" ]; then
                echo -e $TEXT_RED_B && read -p " Are you sure to delete the database (y/N): " selector6
                echo -e $text_reset
                if [ "$selector6" = "y" ] || [ "$selector6" = "Y" ]; then
                    sudo systemctl stop hornet
                    if [ -d "$hornetdir/mainnetdb" ]; then
                        sudo rm -rf $hornetdir/mainnetdb
                    fi
                    if [ -d "$hornetdir/comnetdb" ]; then
                        sudo rm -rf $hornetdir/comnetdir
                    fi
                    if [ -f "$hornetdir/export.bin" ]; then
                        sudo rm -rf $hornetdir/export.bin
                    fi
                    if [ -f "$hornetdir/export_comnet.bin" ]; then
                        sudo rm -rf $hornetdir/export_comnet.bin
                    fi
                    sudo systemctl restart hornet
                    echo -e $text_yellow && echo " Reset of the database finished and hornet restarted!" && echo -e $text_reset
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
            fi

            if [ "$selector" = "4" ]; then
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

            if [ "$selector" = "5" ] ; then
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
            echo -e $text_red "\033[1m\033[4mProject SWARM\033[0m"
            echo ""
            echo -e $text_yellow " SWARM: https://tanglebay.org/swarm"
            echo -e $text_yellow " Donate: https://pool.einfachiota.de/donate"
            echo -e $text_yellow ""
            echo " 1) Add your node to SWARM"
            echo " 2) Remove your node from SWARM"
            echo " 3) Update node on SWARM"
            echo ""
            echo " 4) Show SWARM.log"
            echo " 5) Manage SWARM Auto-Season"
            echo ""
            echo -e "\e[90m-----------------------------------------------------------"
            echo ""
            echo -e $text_yellow "x) Back"
            echo ""
            echo -e " \e[90m==========================================================="
            echo -e $text_yellow && read -p " Please type in your option: " selector
            echo -e $text_reset
            if [ "$selector" = "1" ]; then
                if [ ! -d "$hlmdir/log" ]; then
                    sudo mkdir -p $hlmdir/log
                fi
                if [ ! -f "$hlmdir/log/swarm.log" ]; then
                    sudo touch $hlmdir/log/swarm.log
                fi
                (curl --silent -X POST "https://register.tanglebay.org" -H  "accept: */*" -H  "Content-Type: application/json" -d "{ \"name\": \"$nodename\", \"url\": \"https://$nodeurl:$nodeport\", \"address\": \"$donationaddress\", \"pow\": \"$pownode\" }" |jq '.') > $hlmdir/log/swarm.log
                swarmpwd="$(sudo cat $hlmdir/log/swarm.log |jq '.password')"
                if [ -n "$swarmpwd" ]; then
                    sudo sed -i 's/nodepassword.*/nodepassword='$swarmpwd'/' $hlmcfgdir/swarm.cfg
                fi
                sudo cat $hlmdir/log/swarm.log |jq
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi
            if [ "$selector" = "2" ]; then
                curl --silent -X DELETE https://register.tanglebay.org/$nodepassword |jq
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi
            if [ "$selector" = "3" ]; then
                echo -e $text_red " A node should only be updated in an emergency, as it can lead to the total loss of the current points!"
                echo -e $text_yellow && read -p " Are you sure that you want to update your node (y/N): " selector_swarm_update
                echo -e $text_reset
                if [ "$selector_swarm_update" = "y" ] || [ "$selector_swarm_update" = "Y" ]; then
                    curl --silent --output /dev/null -X DELETE https://register.tanglebay.org/$nodepassword
                    curl --silent -X POST "https://register.tanglebay.org" -H  "accept: */*" -H  "Content-Type: application/json" -d "{ \"name\": \"$nodename\", \"url\": \"https://$nodeurl:$nodeport\", \"address\": \"$donationaddress\", \"pow\": \"$pownode\", \"password\": \"$nodepassword\" }" |jq
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
            fi
            if [ "$selector" = "4" ]; then
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
            echo -e $text_red "\033[1m\033[4mEdit Configurations\033[0m"
            echo -e $text_yellow ""
            echo " 1) Edit Hornet.Service"
            echo " 2) Edit Hornet Config.json"
            echo " 3) Edit Hornet Peering.json"
            echo " 4) Edit Hornet Config_Comnet.json"
            echo ""
            echo " 5) Edit HLM Hornet.cfg"
            echo " 6) Edit HLM Nginx.cfg"
            echo " 7) Edit HLM SWARM.cfg"
            echo ""
            echo -e "\e[90m-----------------------------------------------------------"
            echo ""
            echo -e $text_yellow "x) Back"
            echo ""
            echo -e "\e[90m==========================================================="
            echo -e $text_yellow && read -p " Please type in your option: " selector
            echo -e $text_reset

            if [ "$selector" = "1" ] ; then
                sudo nano /etc/default/hornet
                echo -e $TEXT_RED_B && read -p " Would you like to restart hornet now (y/N): " selector4
                if [ "$selector4" = "y" ] || [ "$selector4" = "y" ]; then
                    sudo systemctl restart hornet
                    echo -e $text_yellow && echo " Hornet node restarted!" && echo -e $text_reset
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
            fi
            if [ "$selector" = "2" ] ; then
                sudo nano $hornetdir/config.json
                echo -e $TEXT_RED_B && read -p " Would you like to restart hornet now (y/N): " selector4
                if [ "$selector4" = "y" ] || [ "$selector4" = "y" ]; then
                    sudo systemctl restart hornet
                    echo -e $text_yellow && echo " Hornet node restarted!" && echo -e $text_reset
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
            fi
            if [ "$selector" = "3" ] ; then
                if [ ! -f "/var/lib/hornet/peering.json" ]; then
                    echo -e $text_yellow && echo " No peering.json found...Downloading config file!" && echo -e $text_reset
                    sudo -u hornet wget -q -O $hornetdir/peering.json https://raw.githubusercontent.com/gohornet/hornet/master/peering.json
                fi
                sudo nano /var/lib/hornet/peering.json
                echo -e $text_yellow && echo " New peering configuration loaded!" && echo -e $text_reset
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi
            if [ "$selector" = "4" ] ; then
                sudo nano $hornetdir/config_comnet.json
                echo -e $TEXT_RED_B && read -p " Would you like to restart hornet now (y/N): " selector4
                if [ "$selector4" = "y" ] || [ "$selector4" = "y" ]; then
                    sudo systemctl restart hornet
                    echo -e $text_yellow && echo " Hornet node restarted!" && echo -e $text_reset
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
            fi
            if [ "$selector" = "5" ] ; then
                currentrelease=$release
                sudo nano $hlmcfgdir/hornet.cfg
                source $hlmcfgdir/hornet.cfg
                if [ "$release" != "$currentrelease" ]; then
                    sudo sh -c 'echo "deb http://ppa.hornet.zone '$release' main" > /etc/apt/sources.list.d/hornet.list'
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
                echo -e $text_yellow && echo " Edit configuration finished!" && echo -e $text_reset
            fi
            if [ "$selector" = "6" ] ; then
                sudo nano $hlmcfgdir/nginx.cfg
                echo -e $text_yellow && echo " Edit configuration finished!" && echo -e $text_reset
            fi
            if [ "$selector" = "7" ] ; then
                if [ -f "$hlmcfgdir/swarm.cfg" ]; then
                    sudo nano $hlmcfgdir/swarm.cfg
                    echo -e $text_yellow && echo " Edit configuration finished!" && echo -e $text_reset
                fi
                if [ -f "$hlmcfgdir/icnp.cfg" ]; then
                    sudo mv $hlmcfgdir/icnp.cfg $hlmcfgdir/swarm.cfg
                    sudo nano $hlmcfgdir/swarm.cfg
                    echo -e $text_yellow && echo " Edit configuration finished!" && echo -e $text_reset
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