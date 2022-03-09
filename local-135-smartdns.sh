chn() {
    sed -e 's|^server=/|nameserver /|' -e 's|114\.114\.114\.114|l|' | grep -Fv cn.debian.org
}

if [ ! -e files/smartdns/address.conf ]; then
    download https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf
    chn < files/tmp/accelerated-domains.china.conf > files/smartdns/address.conf
fi

if [ ! -e files/tmp/address.conf.gz -o files/smartdns/address.conf -nt files/tmp/address.conf.gz ]; then
    echo 'zipping files/smartdns/address.conf'
    gzip -nc files/smartdns/address.conf > files/tmp/address.conf.gz
fi

remote mkdir -p /etc/smartdns
push files/tmp/address.conf.gz /etc/smartdns/address.conf.gz
push files/smartdns/custom.conf /etc/smartdns/custom.conf
push files/smartdns/hotplug /etc/hotplug.d/iface/99-smartdns
push files/smartdns/keep /lib/upgrade/keep.d/oc-smartdns
