oc_service enable vlmcsd
oc_service start vlmcsd

uci -m import dhcp <<EOF
config srvhost 'vlmcsd'
	option srv '_vlmcs._tcp.lan'
	option target '$(uci -q get system.@system[0].hostname).$(uci -q get dhcp.@dnsmasq[0].domain)'
	option port '1688'
	option class '0'
	option weight '100'
EOF

oc_service reload dnsmasq dhcp
