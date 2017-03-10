freeradius_packages() {
    oc_opkg_remove wpad-mini
    oc_opkg_install wpad
    if ! pgrep -x /usr/sbin/radiusd >/dev/null
    then
        [ -z "$config_freeradius_ca" ] && oc_opkg_install freeradius3-democerts
        oc_opkg_install freeradius3 freeradius3-mod-always freeradius3-mod-attr-filter freeradius3-mod-chap freeradius3-mod-detail freeradius3-mod-digest freeradius3-mod-eap-tls freeradius3-mod-exec freeradius3-mod-expiration freeradius3-mod-expr freeradius3-mod-files freeradius3-mod-logintime freeradius3-mod-mschap freeradius3-mod-pap freeradius3-mod-preprocess freeradius3-mod-radutmp freeradius3-mod-realm freeradius3-mod-unix
        [ "$config_freeradius_eap_peap_enabled" = 1 ] && oc_opkg_install freeradius3-mod-eap-mschapv2 freeradius3-mod-eap-peap
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

freeradius_eap() {
    cat >/tmp/freeradius-eap.conf <<EOF
eap {
  default_eap_type = tls
  timer_expire = 60
  ignore_unknown_eap_types = no
  cisco_accounting_username_bug = no
  max_sessions = \${max_requests}
  tls-config tls-common {
    private_key_password =
    private_key_file = \${certdir}/server.pem
    certificate_file = \${certdir}/server.pem
    ca_file = \${cadir}/ca.pem
    dh_file = \${certdir}/dh
    ca_path = \${cadir}
    check_cert_cn = %{User-Name}
    cipher_list = "HIGH"
    ecdh_curve = "secp384r1"
    cache {
      enable = yes
      lifetime = 24 # hours
      max_entries = 255
    }
  }
  tls {
    tls = tls-common
  }
EOF
    if [ "$config_freeradius_eap_peap_enabled" = 1 ]
    then
        cat >>/tmp/freeradius-eap.conf <<EOF
  peap {
    tls = tls-common
    default_eap_type = mschapv2
    copy_request_to_tunnel = no
    use_tunneled_reply = no
    virtual_server = "inner-tunnel"
  }
  mschapv2 {
  }
EOF
    fi
    cat >>/tmp/freeradius-eap.conf <<EOF
}
EOF
    oc_move /tmp/freeradius-eap.conf /etc/freeradius3/mods-available/eap && radiusd_need_restart=1
}

freeradius_users() {
    local rc=1
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
        oc_move /tmp/freeradius-authorize /etc/freeradius3/mods-config/files/authorize && rc=0
        chmod 640 /etc/freeradius3/mods-config/files/authorize
    fi
    return $rc
}

freeradius_service() {
    [ "$radiusd_need_restart" = 1 ] && oc_service restart radiusd -
}

radiusd_need_restart=0
freeradius_packages
freeradius_clients
freeradius_certs
freeradius_eap
echo "$config_freeradius_users" | oc_strip_comment | freeradius_users && radiusd_need_restart=1
freeradius_service
