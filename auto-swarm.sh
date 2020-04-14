#!/bin/bash
source /etc/hlm-cfgs/swarm.cfg
if [ -f "/etc/hlm-cfgs/swarm.cfg" ]; then
    if [ "$nodeurl" != "myhornetnode.ddns.net" ]; then
        curl --silent --output /dev/null -X DELETE https://register.tanglebay.org/nodes/$nodepassword
        curl -X POST "https://register.tanglebay.org/nodes" -H  "accept: */*" -H  "Content-Type: application/json" -d "{ \"name\": \"$nodename\", \"url\": \"https://$nodeurl:$nodeport\", \"address\": \"$donationaddress\", \"pow\": \"$pownode\", \"password\": \"$nodepassword\" }" |jq
    fi
fi
exit 0