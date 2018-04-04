oc_opkg_install sqm-scripts kmod-sched-cake

. /lib/functions/network.sh
network_get_device iface_wan wan

oc_uci_rename sqm eth1 wan
uci batch <<EOF
set sqm.wan.interface='${iface_wan}'
EOF
oc_service reload sqm
oc_uci_merge "$config_sqm"
if oc_uci_commit sqm
then
    echo "sqm: start $iface_wan"
   /usr/lib/sqm/run.sh start "$iface_wan"
fi
