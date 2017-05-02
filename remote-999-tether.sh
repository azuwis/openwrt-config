tether() {
    oc_opkg_install kmod-usb-net-rndis

    uci batch <<EOF
set network.wan.metric=10

set network.wan1=interface
set network.wan1.ifname=usb0
set network.wan1.proto=dhcp
set network.wan1.ipv6=0
set network.wan1.metric=20

set network.wan2=interface
set network.wan2.proto=dhcp
set network.wan2.ipv6=0
set network.wan2.metric=30
EOF
    oc_uci_batch_set "$config_tether"

    oc_service reload network

    oc_uci_add_list 'firewall.@zone[1].network' wan1 wan2
    oc_service reload firewall 2>/dev/null
}

tether
