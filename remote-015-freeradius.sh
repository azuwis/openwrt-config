freeradius_packages() {
    oc_opkg_remove wpad-mini
    oc_opkg_install wpad
    if ! pgrep -x /usr/sbin/radiusd >/dev/null
    then
        [ -z "$config_freeradius_ca" ] && oc_opkg_install freeradius3-democerts
        oc_opkg_install freeradius3 freeradius3-mod-always freeradius3-mod-attr-filter freeradius3-mod-chap freeradius3-mod-detail freeradius3-mod-digest freeradius3-mod-eap-gtc freeradius3-mod-eap-leap freeradius3-mod-eap-md5 freeradius3-mod-eap-mschapv2 freeradius3-mod-eap-peap freeradius3-mod-eap-tls freeradius3-mod-exec freeradius3-mod-expiration freeradius3-mod-expr freeradius3-mod-files freeradius3-mod-logintime freeradius3-mod-mschap freeradius3-mod-pap freeradius3-mod-preprocess freeradius3-mod-radutmp freeradius3-mod-realm freeradius3-mod-unix
        oc_opkg_installed freeradius3-mod-eap-ttls || opkg install --force-overwrite freeradius3-mod-eap-ttls
    fi
}

freeradius_clients() {
    local client
    cat >/tmp/freeradius-clients.conf <<EOF
client localhost {
  ipaddr = 127.0.0.1
  secret = ${config_freeradius_secret}
}
EOF
    chmod 640 /tmp/freeradius-clients.conf
    for client in $config_freeradius_clients
    do
        cat >>/tmp/freeradius-clients.conf <<EOF

client localhost {
  ipaddr = ${client}
  secret = ${config_freeradius_secret}
}
EOF
    done
    oc_move /tmp/freeradius-clients.conf /etc/freeradius3/clients.conf && radiusd_need_restart=1
    chmod 640 /etc/freeradius3/clients.conf
}

freeradius_certs() {
    mkdir -p /etc/freeradius3/certs
    if [ -n "$config_freeradius_ca" ]
    then
        echo -n "$config_freeradius_ca" | tail -n +2 >/tmp/freeradius-ca.pem
        chmod 640 /tmp/freeradius-ca.pem
        oc_move /tmp/freeradius-ca.pem /etc/freeradius3/certs/ca.pem && radiusd_need_restart=1
    fi
    if [ -n "$config_freeradius_cert" ]
    then
        echo -n "$config_freeradius_cert" | tail -n +2 >/tmp/freeradius-cert.pem
        chmod 640 /tmp/freeradius-cert.pem
        oc_move /tmp/freeradius-cert.pem /etc/freeradius3/certs/server.pem && radiusd_need_restart=1
    fi
    if [ -n "$config_freeradius_dh" ]
    then
        echo -n "$config_freeradius_dh" | tail -n +2 >/tmp/freeradius-dh.pem
        chmod 640 /tmp/freeradius-dh.pem
        oc_move /tmp/freeradius-dh.pem /etc/freeradius3/certs/dh && radiusd_need_restart=1
    fi
    chmod 640 /etc/freeradius3/certs/*
}

freeradius_users() {
    if oc_opkg_installed freeradius3-mod-files
    then
        local user pass
        >/tmp/freeradius-authorize
        chmod 640 /tmp/freeradius-authorize
        while read user pass
        do
            cat >>/tmp/freeradius-authorize <<EOF
${user} Cleartext-Password := "${pass}"
EOF
        done
        oc_move /tmp/freeradius-authorize /etc/freeradius3/mods-config/files/authorize && radiusd_need_restart=1
        chmod 640 /etc/freeradius3/mods-config/files/authorize
    fi
}

freeradius_service() {
    [ "$radiusd_need_restart" -eq 1 ] && oc_service restart radiusd -
}

radiusd_need_restart=0
freeradius_packages
freeradius_clients
freeradius_certs
echo "$config_freeradius_users" | oc_strip_comment | freeradius_users
freeradius_service
