network_switch() {
    oc_uci_rename network @switch_vlan[0] vlan1
    oc_uci_rename network @switch_vlan[1] vlan2
    oc_service reload network
}

network_wireless() {
    local i iface bssid key macs nasid list_r0kh list_r1kh j wifi_need_restart
    if oc_uci_exists wireless; then
        # oc_uci_delete wireless.radio0.disabled
        # oc_uci_delete wireless.radio1.disabled
        if oc_uci_exists wireless.radio0
        then
           uci set "wireless.radio0.country=${config_wireless_country}"
           uci set wireless.radio0.noscan=1
        fi
        if oc_uci_exists wireless.radio1
        then
            uci set "wireless.radio1.country=${config_wireless_country}"
            uci set wireless.radio1.noscan=1
        fi
        oc_uci_rename wireless default_radio0 iface0
        oc_uci_rename wireless default_radio1 iface1
        oc_service reload network wireless
        oc_uci_merge "$config_wireless"
        if [ "$config_ieee80211r_enabled" = 1 ]
        then
            for i in $config_ieee80211r_ifaces
            do
                iface="iface$i"
                eval bssid="\$config_ieee80211r_bssid$i"
                eval key="\$config_ieee80211r_key$i"
                eval macs="\$config_ieee80211r_macs$i"
                nasid="$(echo $bssid | tr -d :)"
                uci set "wireless.${iface}.ieee80211r=1"
                uci set "wireless.${iface}.pmk_r1_push=1"
                uci set "wireless.${iface}.auth_cache=1"
                uci set "wireless.${iface}.rsn_preauth=1"
                uci set "wireless.${iface}.mobility_domain=5d73"
                uci set "wireless.${iface}.nasid=${nasid}"
                uci set "wireless.${iface}.r1_key_holder=${nasid}"
                uci set "wireless.${iface}.iapp_interface=lan"
                list_r0kh=''
                list_r1kh=''
                for j in $macs
                do
                    list_r0kh="$list_r0kh ${j},$(echo $j | tr -d :),$key"
                    list_r1kh="$list_r1kh ${j},${j},$key"
                done
                oc_uci_set_list wireless "$iface" r0kh $list_r0kh
                oc_uci_set_list wireless "$iface" r1kh $list_r1kh
            done
        fi
        wifi_need_restart=0
        if uci -q show wireless | grep -qE 'iapp_interface|ieee80211w|ieee80211r|server'; then
            oc_opkg_installed wpad-basic-wolfssl && wifi_need_restart=1
            oc_opkg_remove wpad-basic-wolfssl
            oc_opkg_install wpad-wolfssl
        fi
        oc_service reload network wireless
        if [ "$wifi_need_restart" = 1 ]; then
            wifi
        fi
    fi
}

chmod 600 /etc/config/network /etc/config/wireless
network_switch
oc_uci_merge "$config_network"
network_wireless

uci batch <<EOF
set dhcp.lan.dhcpv6='disabled'
EOF
uci commit
oc_service stop odhcpd
oc_service disable odhcpd
