if ! oc_opkg_installed vlmcsd && ! grep -qF openwrt_azuwis /etc/opkg/customfeeds.conf
then
    echo 'add openwrt_azuwis to /etc/opkg/customfeeds.conf'
    (. /etc/openwrt_release; echo "src/gz openwrt_azuwis http://azuwis.github.io/openwrt-binary-packages/${DISTRIB_ARCH}/azuwis" >> customfeeds.conf)
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
