# if ! grep -qF '/etc/chn-domains' /etc/init.d/dnsmasq; then
#     echo 'patch /etc/init.d/dnsmasq'
#     sed -i -e '/config_foreach dhcp_cname_add cname/{
# n
# n
# a \
# 	while read domain; do echo "server=/$domain/'$config_dnsmasq_local_dns'"; done < /etc/chn-domains >> $CONFIGFILE\
# 	echo "server=/./'$config_chn_domains_remote_dns'" >> $CONFIGFILE\

# }' /etc/init.d/dnsmasq
# fi

if [ "$config_chn_domains_dnsmasq_full" = '1' ]; then
    oc_opkg_remove dnsmasq
    if [ ! -e /tmp/resolv.conf ]; then
        cp /tmp/resolv.conf.auto /tmp/resolv.conf
    fi
    oc_opkg_install dnsmasq-full
    oc_remove /etc/config/dhcp-opkg
fi

uci set dhcp.@dnsmasq[0].remote_dns="$config_chn_domains_remote_dns"
oc_uci_commit dhcp || true
if [ ! -e /tmp/dnsmasq.d/99-chn-domains.conf ]; then
    echo 'run /etc/hotplug.d/iface/99-chn-domains'
    INTERFACE='wan' ACTION='ifup' sh /etc/hotplug.d/iface/99-chn-domains
fi
if [ /etc/chn-domains.gz -nt /tmp/dnsmasq.d/99-chn-domains.conf -o /etc/chn-domains-extra -nt /tmp/dnsmasq.d/99-chn-domains.conf ]; then
    echo 'run /etc/hotplug.d/iface/99-chn-domains'
    rm /tmp/dnsmasq.d/99-chn-domains.conf
    INTERFACE='wan' ACTION='ifup' sh /etc/hotplug.d/iface/99-chn-domains
fi
