oc_opkg_install shadowsocks-libev-ss-rules

echo "$config_shadowsocks" | oc_strip_comment | uci import shadowsocks-libev
oc_service restart shadowsocks-libev

if [ /etc/chn-cidr -nt /var/etc/shadowsocks-libev.json ]; then
    echo 'restart shadowsocks'
    /etc/init.d/shadowsocks-libev restart || true
fi
