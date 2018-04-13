yate_packages() {
    oc_opkg_install yate yate-mod-regexroute yate-mod-regfile yate-mod-yrtpchan yate-mod-ysipchan
    [ "$config_yate_sip_type" = 'tls' ] && oc_opkg_install yate-mod-openssl
}

yate_ysipchan() {
    (
        cat <<EOF
[general]
port=${config_yate_sip_port:-5060}
type=${config_yate_sip_type:-udp}
tcp_idle=600
useragent=${config_yate_sip_useragent:-YATE/2.0.0}
realm=${config_yate_sip_realm:-Yate}
auth_foreign=yes
autochangeparty=yes
; forward_sdp=yes
EOF
        [ "$config_yate_sip_type" = 'tls' ] && cat <<EOF
sslcontext=server
; secure=yes
EOF
        cat <<EOF

[options]
enable=no

[codecs]
speex=yes
h263=yes
h264=yes
vp8=yes
vp9=yes
EOF
    ) >/tmp/yate-ysipchan.conf
    oc_move /tmp/yate-ysipchan.conf /etc/yate/ysipchan.conf && yate_need_restart=1
}

yate_yrtpchan() {
    cat >/tmp/yate-yrtpchan.conf <<EOF
[general]
minport=${config_yate_rtp_minport:-10000}
maxport=${config_yate_rtp_maxport:-20000}
thread=highest
; rtcp=no
EOF
    oc_move /tmp/yate-yrtpchan.conf /etc/yate/yrtpchan.conf && yate_need_restart=1
}

yate_openssl() {
    (
        cat <<EOF
[server]
enable=yes
certificate=server.pem
EOF
        if [ -n "$config_yate_key" ] || [ -n "$config_yate_keyfile" ]
        then
            cat <<EOF
key=server.key
EOF
        fi
    ) >/tmp/yate-openssl.conf
    oc_move /tmp/yate-openssl.conf /etc/yate/openssl.conf && yate_need_restart=1

    if [ -n "$config_yate_cert" ]
    then
        echo -n "$config_yate_cert" | tail -n +2 >/tmp/yate-server.pem
        chmod 640 /tmp/yate-server.pem
        oc_move /tmp/yate-server.pem /etc/yate/server.pem && radiusd_need_restart=1
        if [ -n "$config_yate_key" ]
        then
            echo -n "$config_yate_key" | tail -n +2 >/tmp/yate-server.key
            chmod 640 /tmp/yate-server.key
            oc_move /tmp/yate-server.key /etc/yate/server.key && radiusd_need_restart=1
        fi
    elif [ -n "$config_yate_certfile" ]
    then
        if [ ! -L /etc/yate/server.pem ]
        then
            ln -sf "$config_yate_certfile" /etc/yate/server.pem
        fi
        if [ -n "$config_yate_keyfile" ] && [ ! -L /etc/yate/server.key ]
        then
            ln -sf "$config_yate_keyfile" /etc/yate/server.key
        fi
    fi
}

yate_regfile() {
    local rc=1
    local user pass
    cat >/tmp/yate-regfile.conf <<'EOF'
[general]
file=/var/yate-reg
EOF
    chmod 640 /tmp/yate-regfile.conf
    while read user pass
    do
        cat >>/tmp/yate-regfile.conf <<EOF

[${user}]
password=${pass}
EOF
    done
    oc_move /tmp/yate-regfile.conf /etc/yate/regfile.conf && rc=0
    chmod 640 /etc/yate/regfile.conf
    return $rc
}

yate_regexroute() {
    cat >/tmp/yate-regexroute.conf <<'EOF'
[priorities]
preroute=90
route=90

[default]
${username}^$=-;error=noauth
${username}.=;caller=${username}
^sip:\(.*\)$=return;called=\1
EOF
    oc_move /tmp/yate-regexroute.conf /etc/yate/regexroute.conf && yate_need_restart=1
}

yate_firewall() {
    oc_uci_merge "
package firewall

config rule 'rule_yate_sip'
  option name 'Allow-Yate-Sip'
  option src 'wan'
  option dest_port '${config_yate_sip_port:-5060}'
  option target 'ACCEPT'
  option proto 'tcpudp'

config rule 'rule_yate_rtp'
  option name 'Allow-Yate-Rtp'
  option src 'wan'
  option dest_port '${config_yate_rtp_minport:-10000}:${config_yate_rtp_maxport:-20000}'
  option target 'ACCEPT'
  option proto 'udp'
"
}

yate_service() {
    [ "$yate_need_restart" = 1 ] && oc_service reload yate -
}

yate_need_restart=0
yate_packages
yate_ysipchan
yate_yrtpchan
[ "$config_yate_sip_type" = 'tls' ] && yate_openssl
echo "$config_yate_users" | oc_strip_comment | yate_regfile && yate_need_restart=1
yate_regexroute
yate_firewall
yate_service
