tether_rndis() {
    oc_opkg_install kmod-usb-net-rndis

    local iface wan
    iface="$1"
    wan="$2"

    uci batch <<EOF
set network.wan.metric=10
set network.${wan}=interface
set network.${wan}.ifname=${iface}
set network.${wan}.proto=dhcp
set network.${wan}.ipv6=0
set network.${wan}.metric=20
EOF
    oc_service reload network

    oc_uci_add_list 'firewall.zone_wan.network' "$wan"
    oc_service reload firewall 2>/dev/null
}

tether_wlan() {
    local iface wan
    iface="$1"
    wan="$2"

    uci batch <<EOF
set network.wan.metric=10
set network.${wan}=interface
set network.${wan}.proto=dhcp
set network.${wan}.ipv6=0
set network.${wan}.metric=30
set wireless.${iface}.network=twan2
EOF
    uci commit wireless
    oc_service reload network

    oc_uci_add_list 'firewall.zone_wan.network' "$wan"
    oc_service reload firewall 2>/dev/null
}

if [ -n "$config_tether_rndis" ]
then
    tether_rndis "$config_tether_rndis" twan1
fi

if [ -n "$config_tether_wlan" ]
then
    tether_wlan "$config_tether_wlan" twan2
fi
