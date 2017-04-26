chn_domains() {
    sed -e 's!^server=/!!' -e 's!/114.114.114.114$!!' | grep -Fv cn.debian.org
}

if [ ! -e files/chn_domains/chn-domains ]; then
    download https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf
    chn_domains < files/tmp/accelerated-domains.china.conf > files/chn_domains/chn-domains
fi

if [ ! -e files/tmp/chn-domains.gz -o files/chn_domains/chn-domains -nt files/tmp/chn-domains.gz ]; then
    echo 'zipping files/chn_domains/chn-domains'
    gzip -nc files/chn_domains/chn-domains > files/tmp/chn-domains.gz
fi

remote uci set dhcp.@dnsmasq[0].remote_dns="$config_chn_domains_remote_dns"
remote uci commit

push files/tmp/chn-domains.gz /etc/chn-domains.gz
push files/chn_domains/chn-domains-extra /etc/chn-domains-extra
push files/chn_domains/hotplug /etc/hotplug.d/iface/99-chn-domains

push files/chn_domains/keep /lib/upgrade/keep.d/chn-domains
