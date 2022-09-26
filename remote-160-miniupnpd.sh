oc_opkg_install miniupnpd-nftables

uci batch <<EOF
set upnpd.config.enabled='1'
set upnpd.config.external_iface='wan'
EOF
oc_service restart miniupnpd upnpd
