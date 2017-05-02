tether() {
    oc_opkg_install kmod-usb-net-rndis

    uci batch <<EOF
set network.wan.metric=10

set network.twan1=interface
set network.twan1.ifname=usb0
set network.twan1.proto=dhcp
set network.twan1.ipv6=0
set network.twan1.metric=20

set network.twan2=interface
set network.twan2.proto=dhcp
set network.twan2.ipv6=0
set network.twan2.metric=30
EOF
    oc_uci_batch_set "$config_tether"

    oc_service reload network

    oc_uci_add_list 'firewall.@zone[1].network' twan1 twan2
    oc_service reload firewall 2>/dev/null
}

tether
