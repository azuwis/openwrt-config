echo

# chinadns
echo 'clean chinadns'
oc_service stop chinadns
oc_opkg_remove ChinaDNS
oc_remove /tmp/dnsmasq.d/10-chinadns.conf
echo

# unbound
echo 'clean unbound'
oc_opkg_remove unbound
rm -rf /etc/unbound/
echo

# chn-domains
echo 'clean chn-domains'
oc_remove /etc/chn-domains /etc/hotplug.d/iface/99-chn-domains /tmp/dnsmasq.d/99-chn-domains.conf
echo

# pcap-dnsproxy
echo 'clean pcap-dnsproxy'
oc_opkg_remove pcap-dnsproxy libsodium libpcap
oc_remove /etc/pcap-dnsproxy
echo

oc_service restart dnsmasq -
