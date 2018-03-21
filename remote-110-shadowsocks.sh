shadowsocks() {
    local shadowsocks_installed

    if oc_opkg_installed shadowsocks-libev-ss-rules
    then
        shadowsocks_installed=1
    fi

    oc_opkg_install shadowsocks-libev-ss-rules

    echo "$config_shadowsocks" | oc_strip_comment | uci import shadowsocks-libev
    oc_service restart shadowsocks-libev

    if [ /etc/chn-cidr -nt /var/etc/shadowsocks-libev.json ] || [ -z "$shadowsocks_installed" ]; then
        echo 'restart shadowsocks'
        /etc/init.d/shadowsocks-libev restart || true
    fi
}

shadowsocks
