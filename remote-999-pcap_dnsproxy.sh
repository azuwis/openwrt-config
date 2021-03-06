oc_opkg_install /tmp/libsodium.ipk /tmp/libpcap.ipk /tmp/pcap-dnsproxy.ipk
uci set pcap-dnsproxy.@pcap-dnsproxy[0].enabled='1'
oc_service restart pcap-dnsproxy
local_dns="$(awk '/^# Interface wan$/ {getline; print $2}' /var/resolv.conf.auto)"
sed -e 's/^Local Main = .*/Local Main = 1/' \
    -e 's/^Local Routing = .*/Local Routing = 1/' \
    -e "s/^IPv4 Local DNS Address = .*/IPv4 Local DNS Address = ${local_dns}:53/" \
    /etc/pcap-dnsproxy/Config.conf > /tmp/pcap-dnsproxy-Config.conf
if [ x"$config_pcap_dnsproxy_dns" != x ]; then
    sed -i -e "s/^IPv4 DNS Address = .*/IPv4 DNS Address = ${config_pcap_dnsproxy_dns}/" \
        /tmp/pcap-dnsproxy-Config.conf
fi
if [ x"$config_pcap_dnsproxy_protocol" != x ]; then
    sed -i -e "s/^Protocol = .*/Protocol = ${config_pcap_dnsproxy_protocol}/" \
        /tmp/pcap-dnsproxy-Config.conf
fi
if oc_move /tmp/pcap-dnsproxy-Config.conf /etc/pcap-dnsproxy/Config.conf; then
    oc_service restart pcap-dnsproxy -
fi
