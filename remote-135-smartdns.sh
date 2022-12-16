oc_opkg_install smartdns

uci batch <<EOF
set smartdns.@smartdns[0].enabled='1'
set smartdns.@smartdns[0].auto_set_dnsmasq='1'
set smartdns.@smartdns[0].port='54'
EOF
oc_service restart smartdns
