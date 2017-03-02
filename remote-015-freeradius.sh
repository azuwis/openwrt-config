freeradius_packages() {
    if ! pgrep -x /usr/sbin/radiusd >/dev/null
    then
        oc_opkg_remove wpad-mini
        oc_opkg_install wpad
        oc_opkg_install freeradius3 freeradius3-democerts freeradius3-mod-always freeradius3-mod-attr-filter freeradius3-mod-chap freeradius3-mod-detail freeradius3-mod-digest freeradius3-mod-eap-gtc freeradius3-mod-eap-leap freeradius3-mod-eap-md5 freeradius3-mod-eap-mschapv2 freeradius3-mod-eap-peap freeradius3-mod-eap-tls freeradius3-mod-exec freeradius3-mod-expiration freeradius3-mod-expr freeradius3-mod-files freeradius3-mod-logintime freeradius3-mod-mschap freeradius3-mod-pap freeradius3-mod-preprocess freeradius3-mod-radutmp freeradius3-mod-realm freeradius3-mod-unix
        oc_opkg_installed freeradius3-mod-eap-ttls || opkg install --force-overwrite freeradius3-mod-eap-ttls
    fi
}

freeradius_clients() {
    cat >/tmp/freeradius-clients.conf <<EOF
client localhost {
  ipaddr = 127.0.0.1
  secret = ${config_freeradius_secret}
}
EOF

    for i in $config_freeradius_clients
    do
        cat >>/tmp/freeradius-clients.conf <<EOF

client localhost {
  ipaddr = ${i}
  secret = ${config_freeradius_secret}
}
EOF
    done
}

freeradius_users() {
    local user pass
    >/tmp/freeradius-authorize
    while read user pass
    do
        cat >>/tmp/freeradius-authorize <<EOF
${user} Cleartext-Password := "${pass}"
EOF
    done
}

freeradius_service() {
    local radiusd_need_restart
    radiusd_need_restart=0
    if oc_move /tmp/freeradius-clients.conf /etc/freeradius3/clients.conf
    then
        radiusd_need_restart=1
    fi
    if oc_move /tmp/freeradius-authorize /etc/freeradius3/mods-config/files/authorize
    then
        radiusd_need_restart=1
    fi
    chmod 640 /etc/freeradius3/clients.conf /etc/freeradius3/mods-config/files/authorize
    if [ "$radiusd_need_restart" -eq 1 ]
    then
        oc_service restart radiusd -
    fi
}

freeradius_packages
freeradius_clients
echo "$config_freeradius_users" | oc_strip_comment | freeradius_users
freeradius_service
