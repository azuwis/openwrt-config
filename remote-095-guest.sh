# oc_uci_reset_section network guest
uci batch <<EOF
set network.guest='interface'
set network.guest.proto='static'
set network.guest.ipaddr='192.168.10.1'
set network.guest.netmask='255.255.255.0'
set wireless.${config_guest_wireless}.network=guest
EOF
oc_service reload network

# oc_uci_reset_section dhcp guest
uci batch <<EOF
set dhcp.guest='dhcp'
set dhcp.guest.interface='guest'
set dhcp.guest.start='50'
set dhcp.guest.limit='200'
set dhcp.guest.leasetime='1h'
EOF
oc_service reload dnsmasq dhcp

# oc_uci_reset_section firewall guest_zone
# oc_uci_reset_section firewall guest_forwarding
# oc_uci_reset_section firewall guest_rule_dns
# oc_uci_reset_section firewall guest_rule_dhcp
uci batch <<EOF
set firewall.guest_zone='zone'
set firewall.guest_zone.name='guest'
set firewall.guest_zone.network='guest'
set firewall.guest_zone.input='REJECT'
set firewall.guest_zone.forward='REJECT'
set firewall.guest_zone.output='ACCEPT'
set firewall.guest_forwarding='forwarding'
set firewall.guest_forwarding.src='guest'
set firewall.guest_forwarding.dest='wan'
set firewall.guest_rule_dns='rule'
set firewall.guest_rule_dns.src='guest'
set firewall.guest_rule_dns.dest_port='53'
set firewall.guest_rule_dns.target='ACCEPT'
set firewall.guest_rule_dns.family='ipv4'
set firewall.guest_rule_dhcp='rule'
set firewall.guest_rule_dhcp.src='guest'
set firewall.guest_rule_dhcp.proto='udp'
set firewall.guest_rule_dhcp.src_port='67-68'
set firewall.guest_rule_dhcp.dest_port='67-68'
set firewall.guest_rule_dhcp.target='ACCEPT'
set firewall.guest_rule_dhcp.family='ipv4'
EOF
oc_service reload firewall 2>/dev/null

if oc_opkg_installed sqm-scripts && /etc/init.d/sqm enabled; then
    uci -q show sqm.wan | sed -e "s/sqm.wan/sqm.guest/" -e "s/pppoe-wan/$config_guest_sqm/" -e 's/^/set /' | uci batch
    uci batch <<EOF
set sqm.guest.download=$config_guest_download
set sqm.guest.upload=$config_guest_upload
EOF
fi
oc_service restart sqm
