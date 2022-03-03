guest_network() {
    if [ -n "$CLEANUP" ]
    then
        oc_uci_reset_section network guest
        uci commit
    fi
    oc_uci_merge "$config_guest"
}

guest_dhcp() {
    if [ -n "$CLEANUP" ]
    then
        oc_uci_reset_section dhcp guest
    fi
    uci -m import dhcp <<EOF
config dhcp 'guest'
  option interface 'guest'
  option start '50'
  option limit '200'
EOF
    oc_service reload dnsmasq dhcp
}

guest_firewall() {
    if [ -n "$CLEANUP" ]
    then
        oc_uci_reset_section firewall zone_guest_lan
        oc_uci_reset_section firewall zone_guest_wan
        oc_uci_reset_section firewall forwarding_guest
        oc_uci_reset_section firewall rule_guest_dns
        oc_uci_reset_section firewall rule_guest_dhcp
        uci commit
    fi
    oc_uci_merge "
package firewall

config zone 'zone_guest_lan'
  option name 'guest_lan'
  option network 'guest'
  option input 'REJECT'
  option forward 'REJECT'
  option output 'ACCEPT'

config zone 'zone_guest_wan'
  option name 'guest_wan'
  list network 'wan'
  option input 'DROP'
  option forward 'DROP'
  option output 'ACCEPT'
  option masq '1'
  option mtu_fix '1'

config forwarding 'forwarding_guest'
  option src 'guest_lan'
  option dest 'guest_wan'

config forwarding 'forwarding_guest_lan'
  option src 'lan'
  option dest 'guest_lan'

config rule 'rule_guest_dns'
  option name 'Allow-Guest-DNS'
  option src 'guest_lan'
  option proto 'tcpudp'
  option dest_port '53'
  option target 'ACCEPT'
  option family 'ipv4'

config rule 'rule_guest_dhcp'
  option name 'Allow-Guest-DHCP'
  option src 'guest_lan'
  option proto 'udp'
  option src_port '67-68'
  option dest_port '67-68'
  option target 'ACCEPT'
  option family 'ipv4'
"
}

guest_sqm() {
    if oc_opkg_installed sqm-scripts && /etc/init.d/sqm enabled; then
        # TODO br-guest is wrong for DSA
        uci -q show sqm.wan | sed -e "s/sqm.wan/sqm.guest/" -e "s/pppoe-wan/br-guest/" -e 's/^/set /' | uci batch
        uci batch <<EOF
set sqm.guest.enabled=1
set sqm.guest.download=$config_guest_download
set sqm.guest.upload=$config_guest_upload
EOF
        oc_uci_commit sqm && /usr/lib/sqm/run.sh start "br-guest"
    fi
}

guest_network
guest_dhcp
guest_firewall
guest_sqm
