chn() {
    sed -e 's|^server=/|nameserver /|' -e 's|114\.114\.114\.114|l|' | grep -Fv cn.debian.org
}

if [ ! -e files/smartdns/address.conf ]; then
    download https://github.com/felixonmars/dnsmasq-china-list/raw/master/accelerated-domains.china.conf
    chn < files/tmp/accelerated-domains.china.conf > files/smartdns/address.conf
    cat files/smartdns/extra >> files/smartdns/address.conf
fi

push files/smartdns/address.conf /etc/smartdns/address.conf
push files/smartdns/custom.conf /etc/smartdns/custom.conf
