oc_uci_rename firewall @zone[0] zone_lan
oc_uci_rename firewall @zone[1] zone_wan
uci batch <<EOF
set firewall.zone_wan.forward='DROP'
set firewall.zone_wan.input='DROP'
EOF
oc_uci_batch_set "$config_firewall"
# oc_uci_del_type firewall redirect
firewall_redirect_clean() {
    local all_names proto src_dport dest_ip dest_port name
    all_names=''
    while read -r proto src_dport dest_ip dest_port
    do
        name="${proto}__${src_dport//:/_}"
        all_names="$all_names $name"
    done
    oc_uci_keep_sections firewall redirect "$all_names"
}
firewall_redirect_apply() {
    local proto src_dport dest_ip dest_port name src_ip
    while read -r proto src_dport dest_ip dest_port src_ip
    do
        name="${proto}__${src_dport//:/_}"
        uci set "firewall.${name}=redirect"
        uci set "firewall.${name}.target=DNAT"
        uci set "firewall.${name}.src=wan"
        uci set "firewall.${name}.dest=lan"
        uci set "firewall.${name}.proto=$proto"
        uci set "firewall.${name}.src_dport=$src_dport"
        if [ -n "$dest_ip" ] && [ "$dest_ip" != '-' ]
        then
            uci set "firewall.${name}.dest_ip=$dest_ip"
        fi
        if [ -n "$dest_port" ] && [ "$dest_port" != '-' ]
        then
            uci set "firewall.${name}.dest_port=$dest_port"
        fi
        if [ -n "$src_ip" ] && [ "$src_ip" != '-' ]
        then
            uci set "firewall.${name}.src_ip=$src_ip"
        fi
    done
}
if [ -n "$CLEANUP" ]
then
    echo "$config_redirect" | oc_strip_comment | firewall_redirect_clean
fi
echo "$config_redirect" | oc_strip_comment | firewall_redirect_apply
oc_service reload firewall 2>/dev/null
