chmod 600 /etc/config/network /etc/config/wireless

oc_uci_batch_set "$config_network"
oc_service reload network

if oc_uci_exists wireless; then
    oc_uci_delete wireless.radio0.disabled
    oc_uci_delete wireless.radio1.disabled
    oc_uci_exists wireless.radio0 && uci set wireless.radio0.country=CN
    oc_uci_exists wireless.radio1 && uci set wireless.radio1.country=CN
    oc_uci_rename wireless.@wifi-iface[0] iface0
    oc_uci_rename wireless.@wifi-iface[1] iface1
    oc_uci_batch_set "$config_wireless"
    if [ "$config_ieee80211r_enabled" -eq 1 ]
    then
        for i in $config_ieee80211r_ifaces
        do
            iface="iface$i"
            eval bssid="\$config_ieee80211r_bssid$i"
            nasid="$(echo $bssid | tr -d :)"
            uci set "wireless.${iface}.ieee80211r=1"
            uci set "wireless.${iface}.pmk_r1_push=1"
            uci set "wireless.${iface}.auth_cache=1"
            uci set "wireless.${iface}.rsn_preauth=1"
            uci set "wireless.${iface}.mobility_domain=5d73"
            uci set "wireless.${iface}.nasid=${nasid}"
            uci set "wireless.${iface}.r1_key_holder=${nasid}"
            list_r0kh=''
            list_r1kh=''
            for j in $config_ieee80211r_macs
            do
                list_r0kh="$list_r0kh ${j},$(echo $j | tr -d :),$config_ieee80211r_key"
                list_r1kh="$list_r1kh ${j},${j},$config_ieee80211r_key"
            done
            oc_uci_set_list wireless "$iface" r0kh $list_r0kh
            oc_uci_set_list wireless "$iface" r1kh $list_r1kh
        done
    fi
    wifi_need_restart=0
    if uci -q show wireless | grep -qE 'iapp_interface|ieee80211w|ieee80211r'; then
        oc_opkg_installed wpad-mini && wifi_need_restart=1
        oc_opkg_remove wpad-mini
        oc_opkg_install wpad

        # https://dev.openwrt.org/ticket/19175
        if grep -q uci_get_state /lib/netifd/hostapd.sh && \
                ! grep -qxF '. /lib/config/uci.sh' /lib/netifd/hostapd.sh
        then
            echo 'patch /lib/netifd/hostapd.sh'
            sed -i '1s#^#. /lib/config/uci.sh\n#' /lib/netifd/hostapd.sh
        fi
    fi
    oc_service reload network wireless
    if [ "$wifi_need_restart" -eq 1 ]; then
        wifi
    fi
fi

# uci batch <<EOF
# set dhcp.lan.dhcpv6='disabled'
# EOF
# oc_service restart odhcpd dhcp
