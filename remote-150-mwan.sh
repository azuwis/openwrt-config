mwan_cron() {
    oc_opkg_install curl
    cat >/tmp/mwan_cron <<EOF
#!/bin/sh
config_mwan="$config_mwan"
config_mwan_cron_url="$config_mwan_cron_url"
EOF
    cat >>/tmp/mwan_cron <<'EOF'
for i in $(seq 1 $config_mwan)
do
    sleep "$((0x$(hexdump -n 1 -ve '"%x"' /dev/urandom) % 100))"
    curl --silent --location --user-agent 'Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko' --output /dev/null --interface "pppoe-mwan${i}" "$config_mwan_cron_url"
done
EOF
    mkdir -p ~/bin/
    oc_move /tmp/mwan_cron ~/bin/mwan_cron
    chmod 0755 ~/bin/mwan_cron
    oc_add_cron mwan '17,47 * * * * ~/bin/mwan_cron'
}

mwan_network() {
    # network
    local i
    oc_opkg_install kmod-macvlan

    uci set network.wan.metric=10
    for i in $(seq 1 "$config_mwan")
    do
        uci batch <<EOF
set network.macvlan_mwan${i}=device
set network.macvlan_mwan${i}.name=macvlan-mwan${i}
set network.macvlan_mwan${i}.type=macvlan
set network.macvlan_mwan${i}.ifname=$(uci -q get network.wan.ifname)
set network.mwan${i}=interface
set network.mwan${i}.ifname=macvlan-mwan${i}
set network.mwan${i}.proto=pppoe
set network.mwan${i}.username=$(uci -q get network.wan.username)
set network.mwan${i}.password=$(uci -q get network.wan.password)
set network.mwan${i}.ipv6=0
set network.mwan${i}.metric=$((i+1))0
EOF
    done
    oc_service reload network
}

mwan_firewall() {
    # firewall
    local i
    for i in $(seq 1 "$config_mwan")
    do
        oc_uci_add_list 'firewall.zone_wan.network' "mwan${i}"
    done
    oc_service reload firewall 2>/dev/null
}

mwan_sqm() {
    # sqm
    local i
    if oc_opkg_installed sqm-scripts && /etc/init.d/sqm enabled; then
        for i in $(seq 1 "$config_mwan")
        do
            uci -q show sqm.wan | sed -e "s/sqm.wan/sqm.mwan${i}/" -e "s/pppoe-wan/pppoe-mwan${i}/" -e 's/^/set /' | uci batch
        done
        if oc_uci_commit sqm
        then
            for i in $(seq 1 "$config_mwan")
            do
                /usr/lib/sqm/run.sh start "pppoe-mwan${i}"
            done
        fi
    fi
}

mwan_allwan() {
    echo wan
    for i in $(seq 1 "$config_mwan")
    do
        echo "mwan${i}"
    done
}

mwan_mwan3() {
    # mwan3
    local i port
    oc_opkg_install mwan3 ip-full

    (
        cat <<EOF
config globals 'globals'
  option enabled '1'
  # option local_source 'lan'

EOF
        for i in $(mwan_allwan)
        do
            port="${i/mwan/}"
            if [ "$port" = 'wan' ]
            then
                port=0
            fi
            port="$((port*10+64000))"
            cat <<EOF
config interface '$i'
  option enabled '1'

config member 'm_$i'
  option interface '$i'

config policy 'p_$i'
  list use_member 'm_$i'
  # option last_resort 'default'

# config rule 'r_udp_$port'
#   option proto 'udp'
#   option dest_port '$port:$((port+9))'
#   option use_policy 'p_$i'
EOF
        done
        cat <<EOF
config policy 'balanced'
EOF
        for i in $(mwan_allwan)
        do
            cat <<EOF
  list use_member 'm_$i'
EOF
        done
        cat <<EOF
config rule 'default_rule'
  option dest_ip '0.0.0.0/0'
  option use_policy 'p_wan'
EOF
    ) | uci import mwan3

    if oc_uci_commit mwan3; then
        echo "restart mwan3"
        mwan3 restart 2>/dev/null
    fi
}

if [ "$config_mwan" -gt 0 ]; then
    mwan_network
    mwan_firewall
    mwan_sqm
    mwan_mwan3
    mwan_cron
fi
