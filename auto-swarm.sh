#!/bin/bash
source /etc/hlm-cfgs/swarm.cfg
source /etc/hlm-cfgs/nginx.cfg
if [ -f "/etc/hlm-cfgs/swarm.cfg" ] && [ -f "source /etc/hlm-cfgs/nginx.cfg" ]; then
    if [ "$domain" != "myhornetnode.ddns.net" ]; then
        curl --silent --output /dev/null -X DELETE https://register.tanglebay.org/$nodepassword
        curl -X POST "https://register.tanglebay.org" -H  "accept: */*" -H  "Content-Type: application/json" -d "{ \"name\": \"$nodename\", \"url\": \"https://$domain:$nodeport/api\", \"address\": \"$donationaddress\", \"pow\": \"$pownode\", \"password\": \"$nodepassword\" }" |jq
    fi
fi
exit 0