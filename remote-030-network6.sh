if echo "$config_network6" | grep -qE "^\s*option proto '?6to4'?"; then
    oc_opkg_install 6to4
fi

oc_uci_delete network.globals.ula_prefix
oc_uci_reset_section network wan6
oc_uci_reset_section network henet
uci batch <<EOF
set network.wan6='interface'
set network.wan6.proto='none'
set network.wan6.metric='50'
EOF
oc_uci_merge network "$config_network6"
oc_service reload network

if echo "$config_henet" | grep -qE "^\s*config interface '?henet'?"; then
    oc_opkg_install 6in4
    if ! grep -q 'local max=8$' /lib/netifd/proto/6in4.sh; then
        echo 'patch /lib/netifd/proto/6in4.sh'
        sed -i -e 's/local max=.*$/local max=8/' /lib/netifd/proto/6in4.sh
    fi
    uci batch <<EOF
set network.henet='interface'
set network.henet.proto='6in4'
set network.henet.metric='30'
EOF
    oc_uci_merge network "$config_henet"
    oc_service reload network

    oc_uci_add_list firewall.zone_wan.network henet
    oc_service reload firewall 2>/dev/null
fi
