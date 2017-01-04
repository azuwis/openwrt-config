chn_domains() {
    sed -e 's!^server=/!!' -e 's!/114.114.114.114$!!' | grep -Fv cn.debian.org
}

if [ ! -e files/chn-domains ]; then
    download https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf
    chn_domains < files/tmp/accelerated-domains.china.conf > files/chn-domains
fi

if [ ! -e files/tmp/chn-domains.gz -o files/chn-domains -nt files/tmp/chn-domains.gz ]; then
    echo 'zipping files/chn-domains'
    gzip -nc files/chn-domains > files/tmp/chn-domains.gz
fi

push files/tmp/chn-domains.gz /etc/chn-domains.gz
push files/chn-domains-extra /etc/chn-domains-extra
push files/99-chn-domains /etc/hotplug.d/iface/99-chn-domains

push files/chn-domains.keep /lib/upgrade/keep.d/chn-domains
