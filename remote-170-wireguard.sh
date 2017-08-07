oc_opkg_install wireguard

oc_uci_merge "$config_wireguard"

cat >/tmp/wireguard_cron <<'EOF'
#!/bin/sh
. /lib/functions.sh
handle_interface() {
    local config="$1"
    local proto
    config_get proto "$config" proto
    if [ "$proto" == 'wireguard' ]
    then
        config_foreach handle_peer "wireguard_$config" "$config"
    fi
}
handle_peer() {
    local config="$1"
    local iface="$2"
    local public_key endpoint_host endpoint_port
    config_get public_key "$config" public_key
    config_get endpoint_host "$config" endpoint_host
    config_get endpoint_port "$config" endpoint_port
    if [ -n "$endpoint_host" ] && [ -n "$endpoint_port" ] && echo "$endpoint_host" | grep -qvE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'
    then
        wg set "$iface" peer "$public_key" endpoint "$endpoint_host:$endpoint_port"
    fi
}
config_load network
config_foreach handle_interface interface
EOF
mkdir -p ~/bin/
oc_move /tmp/wireguard_cron ~/bin/wireguard_cron
chmod 0755 ~/bin/wireguard_cron
oc_add_cron wireguard '*/7 * * * * ~/bin/wireguard_cron'
