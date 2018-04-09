asterisk_packages() {
    if [ "$config_asterisk_use_pjsip" = 1 ]
    then
        oc_opkg_install asterisk15-pjsip asterisk15-res-rtp-asterisk asterisk15-bridge-simple
    else
        oc_opkg_install asterisk15-chan-sip asterisk15-res-rtp-asterisk
    fi
}

asterisk_extensions() {
    cat >/tmp/asterisk-extensions.conf <<'EOF'
[internal]
exten=>_XXX,1,Dial(SIP/${EXTEN},60)
EOF
    oc_move /tmp/asterisk-extensions.conf /etc/asterisk/extensions.conf && asterisk_need_restart=1
}

asterisk_sip() {
    local rc=1
    local user pass
    (
        cat <<EOF
[general]
transport=${config_asterisk_sip_transport:-udp}
bindaddr=0.0.0.0:${config_asterisk_sip_port:-5060}
EOF
        echo "$config_asterisk_sip_transport" | grep -qF tcp && cat <<EOF
tcpenable=yes
tcpbindaddr=0.0.0.0:${config_asterisk_sip_port_tcp:-5060}
EOF
        echo "$config_asterisk_sip_transport" | grep -qF tls && cat <<EOF
tlsenable=yes
tlsbindaddr=0.0.0.0:${config_asterisk_sip_port_tls:-5061}
tlscafile=/etc/asterisk/ca.pem
tlscertfile=/etc/asterisk/server.pem
EOF
        cat <<EOF
useragent=${config_asterisk_sip_useragent:-Asterisk}
realm=${config_asterisk_sip_realm:-Asterisk}
videosupport=yes
nat=force_rport,comedia
allowguest=no
alwaysauthreject=yes
srvlookup=no

[peer](!)
type=friend
context=internal
host=dynamic
; nat=yes
disallow=all
; allow=opus
allow=ulaw
allow=vp8
allow=h264
EOF
        echo "$config_asterisk_sip_transport" | grep -qF tls && cat <<EOF
transport=tls
encryption=yes
EOF
    ) >/tmp/asterisk-sip.conf
    chmod 640 /tmp/asterisk-sip.conf
    while read user pass
    do
        cat >>/tmp/asterisk-sip.conf <<EOF

[${user}](peer)
secret=${pass}
EOF
    done
    oc_move /tmp/asterisk-sip.conf /etc/asterisk/sip.conf && rc=0
    chmod 640 /etc/asterisk/sip.conf
    return $rc
}

asterisk_pjsip() {
    local rc=1
    local user pass
    cat >/tmp/asterisk-pjsip.conf <<EOF
[transport-udp]
type=transport
bind=0.0.0.0:${config_asterisk_sip_port:-5060}
protocol=udp

[endpoint](!)
type=endpoint
context=internal
disallow=all
allow=ulaw
allow=h264

[auth](!)
type=auth
auth_type=userpass

[aor](!)
type=aor
max_contacts=1
EOF
    chmod 640 /tmp/asterisk-pjsip.conf
    while read user pass
    do
        cat >>/tmp/asterisk-pjsip.conf <<EOF

[${user}](endpoint)
auth=${user}
aors=${user}

[${user}](auth)
password=${user}
username=${pass}

[${user}](aor)
EOF
    done
    oc_move /tmp/asterisk-pjsip.conf /etc/asterisk/pjsip.conf && rc=0
    chmod 640 /etc/asterisk/pjsip.conf
    return $rc
}

asterisk_tls() {
    oc_opkg_install asterisk15-res-srtp

    if [ -n "$config_asterisk_ca" ]
    then
        echo -n "$config_asterisk_ca" | tail -n +2 >/tmp/asterisk-ca.pem
        chmod 640 /tmp/asterisk-ca.pem
        oc_move /tmp/asterisk-ca.pem /etc/asterisk/ca.pem && asterisk_need_restart=1
    fi

    if [ -n "$config_asterisk_cert" ]
    then
        echo -n "$config_asterisk_cert" | tail -n +2 >/tmp/asterisk-server.pem
        chmod 640 /tmp/asterisk-server.pem
        oc_move /tmp/asterisk-server.pem /etc/asterisk/server.pem && asterisk_need_restart=1
    fi
}

asterisk_rtp() {
    cat >/tmp/asterisk-rtp.conf <<EOF
[general]
rtpstart=${config_asterisk_rtp_start:-10000}
rtpend=${config_asterisk_rtp_end:-20000}
EOF
    oc_move /tmp/asterisk-rtp.conf /etc/asterisk/rtp.conf && asterisk_need_restart=1
}

asterisk_firewall() {
    local config
    config="
package firewall

config rule 'rule_asterisk_rtp'
  option name 'Allow-Asterisk-Rtp'
  option src 'wan'
  option dest_port '${config_asterisk_rtp_start:-10000}:${config_asterisk_rtp_end:-20000}'
  option target 'ACCEPT'
  option proto 'udp'
"

    if echo "$config_asterisk_sip_transport" | grep -qF udp || [ -z "$config_asterisk_sip_transport" ]
    then
        config="$config

    config rule 'rule_asterisk_sip_udp'
    option name 'Allow-Asterisk-Sip-Udp'
    option src 'wan'
    option dest_port '${config_asterisk_sip_port:-5060}'
    option target 'ACCEPT'
    option proto 'udp'
"
    fi
    echo "$config_asterisk_sip_transport" | grep -qF tcp && config="$config

    config rule 'rule_asterisk_sip_tcp'
    option name 'Allow-Asterisk-Sip-Tcp'
    option src 'wan'
    option dest_port '${config_asterisk_sip_port:-5060}'
    option target 'ACCEPT'
    option proto 'tcp'
"
    echo "$config_asterisk_sip_transport" | grep -qF tls && config="$config

    config rule 'rule_asterisk_sip_tls'
    option name 'Allow-Asterisk-Tls'
    option src 'wan'
    option dest_port '${config_asterisk_sip_port_tls:-5061}'
    option target 'ACCEPT'
    option proto 'tcp'
"
    oc_uci_merge "$config"
}

asterisk_service() {
    [ "$asterisk_need_restart" = 1 ] && oc_service reload asterisk -
}

asterisk_need_restart=0
asterisk_packages
asterisk_extensions
if [ "$config_asterisk_use_pjsip" = 1 ]
then
    echo "$config_asterisk_sip_peers" | oc_strip_comment | asterisk_pjsip && asterisk_need_restart=1
else
    echo "$config_asterisk_sip_peers" | oc_strip_comment | asterisk_sip && asterisk_need_restart=1
fi
echo "$config_asterisk_sip_transport" | grep -qF tls && asterisk_tls
asterisk_rtp
asterisk_firewall
asterisk_service
