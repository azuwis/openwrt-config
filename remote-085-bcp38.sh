oc_opkg_install bcp38

. /lib/functions/network.sh
network_get_device iface_wan wan

uci batch <<EOF
set bcp38.@bcp38[0].enabled='1'
set bcp38.@bcp38[0].interface='${iface_wan}'
EOF
oc_service reload firewall bcp38 2>/dev/null
