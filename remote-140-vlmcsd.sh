if ! oc_opkg_installed vlmcsd
then
    oc_opkg_install libustream-openssl20150806
    if ! grep -qF openwrt_azuwis /etc/opkg/customfeeds.conf
    then
        echo 'add openwrt_azuwis to /etc/opkg/customfeeds.conf'
        (. /etc/openwrt_release; echo "src/gz openwrt_azuwis http://azuwis.github.io/openwrt-binary-packages/${DISTRIB_ARCH}/azuwis" >> /etc/opkg/customfeeds.conf)
    fi
    if ! [ -e /etc/opkg/keys/8b2b6e8037ed6eda ]
    then
        cat >/etc/opkg/keys/8b2b6e8037ed6eda <<EOF
untrusted comment: Local build key
RWSLK26AN+1u2lMBvSv9Pv07OptFN6R0dhl7dr9JIDSgQMYcLebP3qYp
EOF
    fi
    opkg update
fi

oc_opkg_install vlmcsd

uci -m import dhcp <<EOF
config srvhost 'vlmcsd'
	option srv '_vlmcs._tcp.lan'
	option target '$(uci -q get system.@system[0].hostname).$(uci -q get dhcp.@dnsmasq[0].domain)'
	option port '1688'
	option class '0'
	option weight '100'
EOF

oc_service reload dnsmasq dhcp
