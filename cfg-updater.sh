#!/bin/bash
hlmdir="/var/lib/hornet-light-manager"
hlmcfgdir="/etc/hlm-cfgs"
dlhornetcfg="https://raw.githubusercontent.com/TangleBay/hlm-cfgs/master/hornet.cfg"
dlnginxcfg="https://raw.githubusercontent.com/TangleBay/hlm-cfgs/master/nginx.cfg"
dlswarmcfg="https://raw.githubusercontent.com/TangleBay/hlm-cfgs/master/swarm.cfg"
source $hlmcfgdir/hornet.cfg
source $hlmcfgdir/nginx.cfg
source $hlmcfgdir/swarm.cfg

if [ "$hornetcfgversion" != "0.0.1" ] || [ ! -n "$hornetcfgversion" ]; then
    sudo wget -O $hlmcfgdir/hornet.cfg $dlhornetcfg
    sudo sed -i 's/release.*/release='$release'/' $hlmcfgdir/hornet.cfg
    sudo sed -i 's/dashuser.*/dashuser=\"'$dashuser'\"/' $hlmcfgdir/hornet.cfg
    sudo sed -i 's/dashpw.*/dashpw=\"'$dashpw'\"/' $hlmcfgdir/hornet.cfg
    sudo sed -i 's/neighborport.*/neighborport='$neighborport'/' $hlmcfgdir/hornet.cfg
    sudo sed -i 's/autopeeringport.*/autopeeringport='$autopeeringport'/' $hlmcfgdir/hornet.cfg
    sudo sed -i 's/maxlmi.*/maxlmi='$maxlmi'/' $hlmcfgdir/hornet.cfg
    sudo sed -i 's/logpruning.*/logpruning='$logpruning'/' $hlmcfgdir/hornet.cfg
    sudo sed -i 's/logsize.*/logsize='$logsize'/' $hlmcfgdir/hornet.cfg
fi

if [ "$nginxcfgversion" != "0.0.1" ] || [ ! -n "$nginxcfgversion" ]; then
    sudo wget -O $hlmcfgdir/nginx.cfg $dlnginxcfg
    sudo sed -i 's/domain.*/domain=\"'$domain'\"/' $hlmcfgdir/nginx.cfg
    sudo sed -i 's/nodeport.*/nodeport='$nodeapiport'/' $hlmcfgdir/nginx.cfg
fi

if [ "$swarmcfgversion" != "0.0.1" ] || [ ! -n "$swarmcfgversion" ]; then
    sudo wget -O $hlmcfgdir/swarm.cfg $dlswarmcfg
    sudo sed -i 's/nodename.*/nodename=\"'$nodename'\"/' $hlmcfgdir/swarm.cfg
    sudo sed -i 's/pownode.*/pownode='$pownode'/' $hlmcfgdir/swarm.cfg
    sudo sed -i 's/donationaddress.*/donationaddress=\"'$donationaddress'\"/' $hlmcfgdir/swarm.cfg
    sudo sed -i 's/nodepassword.*/nodepassword=\"'$nodepassword'\"/' $hlmcfgdir/swarm.cfg
fi

exit 0