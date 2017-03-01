oc_opkg_install shadowsocks-libev

if ! oc_uci_exists firewall.shadowsocks_libev; then
    uci batch <<EOF
set firewall.shadowsocks_libev=include
set firewall.shadowsocks_libev.type=script
set firewall.shadowsocks_libev.path=/usr/share/shadowsocks-libev/firewall.include
set firewall.shadowsocks_libev.reload=1
EOF
    oc_service reload firewall
fi

uci set shadowsocks-libev.@shadowsocks-libev[0].ignore_list='/etc/chn-cidr'
oc_uci_batch_set "$config_shadowsocks_common"
oc_uci_batch_set "$config_shadowsocks"
oc_service restart shadowsocks-libev

if [ /etc/chn-cidr -nt /var/etc/shadowsocks-libev.json ]; then
    echo 'restart shadowsocks'
    /etc/init.d/shadowsocks-libev restart || true
fi
