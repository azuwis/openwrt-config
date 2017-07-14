oc_opkg_install shadowsocks-libev-ss-rules

oc_uci_batch_set "$config_shadowsocks_common"
oc_uci_batch_set "$config_shadowsocks"
oc_service restart shadowsocks-libev

if [ /etc/chn-cidr -nt /var/etc/shadowsocks-libev.json ]; then
    echo 'restart shadowsocks'
    /etc/init.d/shadowsocks-libev restart || true
fi
