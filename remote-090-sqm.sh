oc_opkg_install sqm-scripts kmod-sched-cake

. /lib/functions/network.sh
network_get_device iface_wan wan

oc_uci_rename sqm eth1 wan
uci batch <<EOF
set sqm.wan.enabled='0'
set sqm.wan.interface='${iface_wan}'
set sqm.wan.script='piece_of_cake.qos'
EOF
oc_uci_merge "$config_sqm"
if oc_uci_commit sqm
then
    echo "sqm: start $iface_wan"
   /usr/lib/sqm/run.sh start "$iface_wan"
fi
