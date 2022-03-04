oc_opkg_install smartdns

uci batch <<EOF
set smartdns.@smartdns[0].enabled='1'
set smartdns.@smartdns[0].redirect='dnsmasq-upstream'
EOF
oc_service restart smartdns
