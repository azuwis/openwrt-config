if [ -n "$CLEANUP" ]
then
    oc_uci_reset_section network guest
fi
uci -m import network <<EOF
config interface 'guest'
  option proto 'static'
  option ipaddr '192.168.10.1'
  option netmask '255.255.255.0'
EOF
oc_service reload network
uci -m import wireless <<EOF
config wifi-iface '${config_guest_wireless}'
  option network 'guest'
  option isolate '1'
EOF
oc_service reload network wireless

if [ -n "$CLEANUP" ]
then
    oc_uci_reset_section dhcp guest
fi
uci -m import dhcp <<EOF
config dhcp 'guest'
  option interface 'guest'
  option start '50'
  option limit '200'
  option leasetime '1h'
EOF
oc_service reload dnsmasq dhcp

if [ -n "$CLEANUP" ]
then
    oc_uci_reset_section firewall guest_zone
    oc_uci_reset_section firewall guest_forwarding
    oc_uci_reset_section firewall guest_rule_dns
    oc_uci_reset_section firewall guest_rule_dhcp
fi
uci -m import firewall <<EOF
config zone 'zone_guest'
  option name 'guest'
  option network 'guest'
  option input 'REJECT'
  option forward 'REJECT'
  option output 'ACCEPT'

config forwarding 'forwarding_guest'
  option src 'guest'
  option dest 'wan'

config rule 'rule_guest_dns'
  option name 'Allow-Guest-DNS'
  option src 'guest'
  option proto 'tcpudp'
  option dest_port '53'
  option target 'ACCEPT'
  option family 'ipv4'

config rule 'rule_guest_dhcp'
  option name 'Allow-Guest-DHCP'
  option src 'guest'
  option proto 'udp'
  option src_port '67-68'
  option dest_port '67-68'
  option target 'ACCEPT'
  option family 'ipv4'
EOF
oc_service reload firewall 2>/dev/null

if oc_opkg_installed sqm-scripts && /etc/init.d/sqm enabled; then
    uci -q show sqm.wan | sed -e "s/sqm.wan/sqm.guest/" -e "s/pppoe-wan/$config_guest_sqm/" -e 's/^/set /' | uci batch
    uci batch <<EOF
set sqm.guest.download=$config_guest_download
set sqm.guest.upload=$config_guest_upload
EOF
fi
oc_uci_commit sqm && /usr/lib/sqm/run.sh start "$config_guest_sqm"
