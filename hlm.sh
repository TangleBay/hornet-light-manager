#!/bin/bash

############################################################################################################################################################
############################################################################################################################################################
# DO NOT EDIT THE LINES BELOW !!! DO NOT EDIT THE LINES BELOW !!! DO NOT EDIT THE LINES BELOW !!! DO NOT EDIT THE LINES BELOW !!!
############################################################################################################################################################
############################################################################################################################################################

version=0.0.1

############################################################################################################################################################

pwdcmd=`dirname "$BASH_SOURCE"`
source $pwdcmd/config.cfg

TEXT_RED_B='\e[1;31m'
text_yellow='\e[33m'
text_green='\e[32m'
text_red='\e[31m'
text_reset='\e[0m'

hornetdir="/var/lib/hornet"
githubrepo="https://raw.githubusercontent.com/TangleBay/hornet-light-manager"
hlmcfgs="https://raw.githubusercontent.com/TangleBay/hlm-cfgs/master"
snapshot="$(curl -s $hlmcfgs/snapshot.cfg)"
latesthlm="$(curl -s https://api.github.com/repos/TangleBay/hornet-light-manager/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')"

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
    sudo apt install nano -y > /dev/null
    clear
fi

if [ "$version" != "$latesthlm" ]; then
    echo -e $TEXT_RED_B && echo " New version available (v$latesthlm)! Downloading new version..." && echo -e $text_reset
    ( cd $pwdcmd ; sudo git pull > /dev/null )
    ( cd $pwdcmd ; sudo git reset --hard origin/$branch )
    sudo chmod +x $pwdcmd/hlm.sh $pwdcmd/watchdog.sh
    sudo nano $pwdcmd/config.cfg
    ScriptLoc=$(readlink -f "$0")
    exec "$ScriptLoc"
    exit 0
fi

if [ ! -f "$pwdcmd/icnp.cfg" ]; then
    echo -e $text_yellow && echo " No pool config detected...Downloading pool config file!" && echo -e $text_reset
    sudo wget -q -O $pwdcmd/icnp.cfg $hlmcfgs/icnp.cfg
fi

counter=0
while [ $counter -lt 1 ]; do
    clear
    source $pwdcmd/config.cfg
    source $pwdcmd/icnp.cfg

    nodetempv="$(curl -s http://127.0.0.1:14265 -X POST -H 'Content-Type: application/json' -H 'X-IOTA-API-Version: 1' -d '{"command": "getNodeInfo"}' | jq '.appVersion')"
    nodev="${nodetempv%\"}"
    nodev="${nodev#\"}"
    sync="$(curl -s https://nodes.tanglebay.org -X POST -H 'Content-Type: application/json' -H 'X-IOTA-API-Version: 1' -d '{"command": "getNodeInfo"}' | jq '.isSynced')"

    sudo crontab -l | grep -q $pwdcmd/watchdog.sh && watchdog=active || watchdog=inactive
    if [ -f "$pwdcmd/log/watchdog.log" ]; then
        watchdogcount="$(cat $pwdcmd/log/watchdog.log | sed -n -e '1{p;q}')"
        watchdogtime="$(cat $pwdcmd/log/watchdog.log | sed -n -e '2{p;q}')"
    fi

    ############################################################################################################################################################

    echo ""
    echo -e $text_yellow "\033[1m\033[4mWelcome to the Hornet lightweight manager! [v$version]\033[0m"
    echo ""
    echo -e $text_red " Hornet Node"
    if [ -n "$nodev" ]; then
        if [ "$nodev" = "$latesthornet" ]; then
            echo -e "$text_yellow Version:$text_green $nodev"
        else
            echo -e "$text_yellow Version:$text_red $nodev"
        fi
    else
        echo -e "$text_yellow Version:$text_red N/A"
    fi
    if [ "-n "$nodev"" ]; then
        if [ "$sync" = "false" ]; then
            echo -e "$text_yellow Status:$text_red not synced"
        else
            echo -e "$text_yellow Status:$text_green synced"
        fi
    else
        echo -e "$text_yellow Status:$text_red offline"
    fi
    echo ""
    if [ "$watchdog" != "active" ]; then
        echo -e "$text_yellow Watchdog:$text_red $watchdog"
    else
        echo -e "$text_yellow Watchdog:$text_green $watchdog"
        echo -e "$text_yellow Restarts:$text_red $watchdogcount"
        if [ -n "$watchdogtime" ]; then
            echo -e "$text_yellow Last restart: $watchdogtime"
        fi
    fi
    echo ""

    echo -e "\e[90m==========================================================="
    echo ""
    echo -e $text_red "\033[1m\033[4mManagement\033[0m"
    echo ""
    echo -e $text_yellow
    echo " 1) Install Management"
    echo ""
    echo " 2) Hornet Management"
    echo ""
    echo " 3) IOTA Community Node Pool"
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
            echo -e $text_red "\033[1m\033[4mInstaller Manager\033[0m"
            echo -e $text_yellow ""
            echo " 1) Install Hornet"
            echo " 2) Remove Hornet"
            echo ""
            echo " 3) Install HTTPS proxy"
            echo ""
            echo " 4) Install Watchdog"
            echo " 5) Reset Hornet-Light-Manager"
            echo ""
            echo -e "\e[90m-----------------------------------------------------------"
            echo ""
            echo -e $text_yellow "x) Back"
            echo ""
            echo -e "\e[90m==========================================================="
            echo -e $text_yellow && read -p " Please type in your option: " selector
            echo -e $text_reset
            if [ "$selector" = "1" ]; then
                if [ ! -f "$hornetdir/hornet" ]; then
                    sudo wget -qO - https://ppa.hornet.zone/pubkey.txt | sudo apt-key add -
                    sudo sh -c 'echo "deb http://ppa.hornet.zone '$release' main" > /etc/apt/sources.list.d/hornet.list'
                    sudo apt update
                    sudo apt install hornet -y
                    check="$(systemctl show -p ActiveState --value hornet)"
                    if [ "$check" != "active" ]; then
                        sudo systemctl restart hornet
                    fi
                    echo ""
                    echo -e $TEXT_RED_B
                    echo " You need to open the follow ports in your home router for peering"
                    echo " Ports: 14626/UDP & 15600/tcp"
                    echo ""
                    echo -e $text_yellow
                    echo " Hornet installation finished!"
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...' && echo -e $text_reset
                else
                    echo -e $text_red " Hornet already installed. Please remove first!"
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...' && echo -e $text_reset
                fi
            fi

            if [ "$selector" = "2" ]; then
                echo -e $TEXT_RED_B && read -p " Are you sure you want to remove Hornet (y/N): " selector_hornetremove
                if [ "$selector_hornetremove" = "y" ] || [ "$selector_hornetremove" = "Y" ]; then
                    sudo systemctl stop hornet
                    sudo apt purge hornet -y
                    echo -e $text_red " Hornet was successfully removed!"
                    echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                    echo -e $text_reset
                fi
            fi

            if [ "$selector" = "3" ]; then
                echo -e $text_yellow && echo " Installing necessary packages..." && echo -e $text_reset
                sudo apt install software-properties-common -y
                sudo add-apt-repository ppa:certbot/certbot -y > /dev/null
                sudo apt update && sudo apt install python-certbot-nginx -y
                sudo apt update && sudo apt dist-upgrade -y && sudo apt upgrade -y && apt autoremove -y

                echo -e $text_yellow && echo " Updating Nginx..." && echo -e $text_reset
                sudo mkdir /etc/systemd/system/nginx.service.d
                sudo printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
                sudo systemctl daemon-reload

                echo -e $text_yellow && echo " Copying Nginx configuration..." && echo -e $text_reset
                sudo cp $pwdcmd/nginx-config.template /etc/nginx/sites-available/default
                sudo find /etc/nginx/sites-available/default -type f -exec sed -i 's/domain.tld/'$domain'/g' {} \;
                sudo find /etc/nginx/sites-available/default -type f -exec sed -i 's/14266/'$apiport'/g' {} \;
                sudo find /etc/nginx/sites-available/default -type f -exec sed -i 's/14267/'$dashport'/g' {} \;
                sudo find /etc/nginx/nginx.conf -type f -exec sed -i 's/\# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/g' {} \;
                dashpw="$(mkpasswd -m sha-512 $dashpw)"
                sudo echo "$dashuser:$dashpw" > /etc/nginx/.htpasswd
                sudo systemctl restart nginx

                echo -e $text_yellow && echo " Starting SSL-Certificate installation..." && echo -e $text_reset
                sudo certbot --nginx -d $domain

                if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
                    sudo cp $pwdcmd/nginx-config.template /etc/nginx/sites-available/default
                    sudo find /etc/nginx/sites-available/default -type f -exec sed -i 's/domain.tld/'$domain'/g' {} \;
                    sudo find /etc/nginx/sites-available/default -type f -exec sed -i 's/14266/'$apiport'/g' {} \;
                    sudo find /etc/nginx/sites-available/default -type f -exec sed -i 's/14267/'$dashport'/g' {} \;
                    sudo find /etc/nginx/sites-available/default -type f -exec sed -i 's/\#RjtV27dw/''/g' {} \;
                    sudo systemctl restart nginx
                fi
                echo -e $text_yellow && echo " Reverse proxy installation finished!" && echo -e $text_reset
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi

            if [ "$selector" = "4" ]; then
                echo -e $TEXT_RED_B && read -p " Would you like to (1)enable/(2)disable or (c)ancel hornet watchdog: " selector_watchdog
                echo -e $text_reset
                croncmd="$pwdcmd/watchdog.sh"
                cronjob="*/15 * * * * $croncmd"
                if [ "$selector_watchdog" = "1" ]; then
                    echo -e $text_yellow && echo " Enable hornet watchdog..." && echo -e $text_reset
                    sudo mkdir -p $pwdcmd/log
                    sudo echo "0" > $pwdcmd/log/watchdog.log
                    sudo chmod +x $pwdcmd/watchdog.sh
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
                echo -e $TEXT_RED_B && read -p " Are you sure you want to reset HLM (y/N): " selector_hlmreset
                if [ "$selector_hlmreset" = "y" ] || [ "$selector_hlmreset" = "Y" ]; then
                    ( cd $pwdcmd ; sudo git pull )
                    ( cd $pwdcmd ; sudo git reset --hard origin/$branch )
                    sudo chmod +x $pwdcmd/hlm.sh $pwdcmd/watchdog.sh
                    sudo nano $pwdcmd/config.cfg
                    echo -e $text_red " HLM was successfully reset!"
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
            echo " 3) Reset mainnet database"
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
                sudo systemctl stop hornet
                sudo rm -rf $hornetdir/mainnetdb/
                echo -e $TEXT_RED_B && read -p " Would you like to download the latest snapshot (y/N): " selector6
                echo -e $text_reset
                if [ "$selector6" = "y" ] || [ "$selector6" = "Y" ]; then
                    echo -e $text_yellow && echo " Downloading snapshot file..." && echo -e $text_reset
                    sudo -u hornet wget -O $hornetdir/export.bin $snapshot
                fi
                sudo systemctl restart hornet
                echo -e $text_yellow && echo " Reset of the database finished and hornet restarted!" && echo -e $text_reset
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi

            if [ "$selector" = "4" ]; then
                if [ -f "/etc/nginx/.htpasswd" ]; then
                    echo "$dashuser:$dashpw" > /etc/nginx/.htpasswd
                    echo -e $text_yellow && echo " Hornet Dashboard login updated!" && echo -e $text_reset
                else
                    echo -e $text_red "Please install nginx first!"
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
            echo -e $text_red "\033[1m\033[4meinfachIOTA Pool\033[0m"
            echo ""
            echo -e $text_yellow " Pool: https://pool.einfachiota.de"
            echo -e $text_yellow ""
            echo " 1) Add your node to the pool"
            echo " 2) Remove your node from the pool"
            echo " 3) Update node on the pool"
            echo ""
            echo -e "\e[90m-----------------------------------------------------------"
            echo ""
            echo -e $text_yellow "x) Back"
            echo ""
            echo -e "\e[90m==========================================================="
            echo -e $text_yellow && read -p " Please type in your option: " selector
            echo -e $text_reset
            if [ "$selector" = "1" ]; then
                curl -X POST "https://register.tanglebay.org/nodes" -H  "accept: */*" -H  "Content-Type: application/json" -d "{ \"name\": \"$nodename\", \"url\": \"https://$nodeurl:$nodeport\", \"address\": \"$donationaddress\", \"pow\": \"$pownode\" }" |jq
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi
            if [ "$selector" = "2" ]; then
                curl -X DELETE https://register.tanglebay.org/nodes/$nodepassword |jq
                echo -e $TEXT_RED_B && pause ' Press [Enter] key to continue...'
                echo -e $text_reset
            fi
            if [ "$selector" = "3" ]; then
                curl --silent --output /dev/null -X DELETE https://register.tanglebay.org/nodes/$nodepassword
                curl -X POST "https://register.tanglebay.org/nodes" -H  "accept: */*" -H  "Content-Type: application/json" -d "{ \"name\": \"$nodename\", \"url\": \"https://$nodeurl:$nodeport\", \"address\": \"$donationaddress\", \"pow\": \"$pownode\", \"password\": \"$nodepassword\" }" |jq
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
            echo " 1) Edit Hornet service"
            echo " 2) Edit Hornet config"
            echo " 3) Edit Hornet peering.json"
            echo " 4) Edit Hornet ComNet config"
            echo " 5) Edit HLM config.cfg"
            echo " 6) Edit ICNP config"
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
                if [ ! -f "$pwdcmd/config.cfg" ]; then
                    echo -e $text_yellow && echo " No config file found...Downloading config file!" && echo -e $text_reset
                    sudo wget -q -O $pwdcmd/config.cfg $githubrepo/$hlm/config.cfg
                    echo -e $text_yellow && echo " Please try again!" && echo -e $text_reset
                else
                    sudo nano $pwdcmd/config.cfg
                    echo -e $text_yellow && echo " Edit configuration finished!" && echo -e $text_reset
                fi
            fi
            if [ "$selector" = "6" ] ; then
                if [ ! -f "$pwdcmd/icnp.cfg" ]; then
                    echo -e $text_yellow && echo " No config file found...Downloading config file!" && echo -e $text_reset
                    sudo wget -q -O $pwdcmd/icnp.cfg $hlmcfgs/icnp.cfg
                    echo -e $text_yellow && echo " Please try again!" && echo -e $text_reset
                else
                    sudo nano $pwdcmd/icnp.cfg
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
