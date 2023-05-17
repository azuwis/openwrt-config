if [ ! -e files/shadowsocks/chn-cidr ]; then
    download https://github.com/17mon/china_ip_list/raw/master/china_ip_list.txt files/shadowsocks/chn-cidr
    cat >> files/shadowsocks/chn-cidr <<EOF
64.62.200.2/32
1.1.1.0/24
EOF
fi
push files/shadowsocks/chn-cidr /etc/chn-cidr
push files/shadowsocks/keep /lib/upgrade/keep.d/oc-shadowsocks
push files/shadowsocks/ss /root/bin/ss
