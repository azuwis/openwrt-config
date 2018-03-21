chn_cidr() {
    awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' | sort -V | aggregate
}
if [ ! -e files/shadowsocks/chn-cidr ]; then
    download http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest
    chn_cidr < files/tmp/delegated-apnic-latest > files/shadowsocks/chn-cidr
    cat >> files/shadowsocks/chn-cidr <<EOF
64.62.200.2/32
1.1.1.0/24
EOF
fi
push files/shadowsocks/chn-cidr /etc/chn-cidr
push files/shadowsocks/keep /lib/upgrade/keep.d/oc-shadowsocks
push files/shadowsocks/ss /root/bin/ss
