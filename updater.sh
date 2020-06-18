#!/bin/bash
hlmdir="/var/lib/hornet-light-manager"
hlmcfgdir="/etc/hlm-cfgs"
dlhornetcfg="https://raw.githubusercontent.com/TangleBay/hlm-cfgs/master/hornet.cfg"
dlnginxcfg="https://raw.githubusercontent.com/TangleBay/hlm-cfgs/master/nginx.cfg"
dlswarmcfg="https://raw.githubusercontent.com/TangleBay/hlm-cfgs/master/swarm.cfg"
dlwatchdogcfg="https://raw.githubusercontent.com/TangleBay/hlm-cfgs/master/watchdog.cfg"
source $hlmcfgdir/hornet.cfg
source $hlmcfgdir/nginx.cfg
source $hlmcfgdir/swarm.cfg
source $hlmcfgdir/watchdog.cfg

if [ "$hornetcfgversion" != "0.0.4" ] || [ "$hornetcfgversion" = "" ]; then
    sudo wget -q -O $hlmcfgdir/hornet.cfg $dlhornetcfg
    sudo sed -i 's/release.*/release='$release'/' $hlmcfgdir/hornet.cfg
    sudo sed -i 's/network.*/network='$network'/' $hlmcfgdir/hornet.cfg
    sudo sed -i 's/pow.*/pow='$pow'/' $hlmcfgdir/hornet.cfg
    sudo sed -i 's/neighborport.*/neighborport='$neighborport'/' $hlmcfgdir/hornet.cfg
    sudo sed -i 's/autopeeringport.*/autopeeringport='$autopeeringport'/' $hlmcfgdir/hornet.cfg
    sudo sed -i 's/pruning.*/pruning='$pruning'/' $hlmcfgdir/hornet.cfg
    sudo sed -i 's/pruningdelay.*/pruningdelay='$pruningdelay'/' $hlmcfgdir/hornet.cfg
fi

if [ "$nginxcfgversion" != "0.0.2" ] || [ "$nginxcfgversion" = "" ]; then
    sudo wget -q -O $hlmcfgdir/nginx.cfg $dlnginxcfg
    sudo sed -i 's/domain.*/domain=\"'$domain'\"/' $hlmcfgdir/nginx.cfg
    sudo sed -i 's/nodeport.*/nodeport='$nodeapiport'/' $hlmcfgdir/nginx.cfg
    sudo sed -i 's/dashuser.*/dashuser=\"'$dashuser'\"/' $hlmcfgdir/nginx.cfg
    sudo sed -i 's/dashpw.*/dashpw=\"'$dashpw'\"/' $hlmcfgdir/nginx.cfg
fi

if [ "$swarmcfgversion" != "0.0.1" ] || [ "$swarmcfgversion" = "" ]; then
    sudo wget -q -O $hlmcfgdir/swarm.cfg $dlswarmcfg
    sudo sed -i "s/nodename.*/nodename=\"$nodename\"/g" $hlmcfgdir/swarm.cfg
    sudo sed -i 's/pownode.*/pownode='$pownode'/' $hlmcfgdir/swarm.cfg
    sudo sed -i 's/donationaddress.*/donationaddress=\"'$donationaddress'\"/' $hlmcfgdir/swarm.cfg
    sudo sed -i 's/nodepassword.*/nodepassword=\"'$nodepassword'\"/' $hlmcfgdir/swarm.cfg
fi

if [ "$watchdogcfgversion" != "0.0.1" ] || [ "$swarmcfgversion" = "" ]; then
    sudo wget -q -O $hlmcfgdir/watchdog.cfg $dlwatchdogcfg
    sudo sed -i 's/autoupdate.*/autoupdate='$autoupdate'/' $hlmcfgdir/watchdog.cfg
    sudo sed -i 's/checksync.*/checksync='$checksync'/' $hlmcfgdir/watchdog.cfg
    sudo sed -i 's/maxlmi.*/maxlmi='$maxlmi'/' $hlmcfgdir/watchdog.cfg
    sudo sed -i 's/logpruning.*/logpruning='$logpruning'/' $hlmcfgdir/watchdog.cfg
    sudo sed -i 's/logsize.*/logsize='$logsize'/' $hlmcfgdir/watchdog.cfg
fi