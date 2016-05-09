pcap_dns_proxy_pkg() {
    local name="$1"
    local version="$2"
    download_push "https://github.com/wongsyrone/openwrt-Pcap_DNSProxy/raw/prebuilt-ipks/chaos_calmer/15.05.1/${arch_full}/${name}_${version}_${arch}.ipk" "/tmp/${name}.ipk" "$name"
}

pcap_dns_proxy_pkg 'libsodium' '1.0.10-1'
pcap_dns_proxy_pkg 'libpcap' '1.7.4-1'
pcap_dns_proxy_pkg 'pcap-dnsproxy' '0.4.6.1-1'
