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
exten=>_6XXX,1,Dial(SIP/${EXTEN},60)
EOF
    oc_move /tmp/asterisk-extensions.conf /etc/asterisk/extensions.conf && asterisk_need_restart=1
}

asterisk_sip() {
    local rc=1
    local user pass
    cat >/tmp/asterisk-sip.conf <<EOF
[general]
bindaddr = 0.0.0.0:${config_asterisk_sip_port:-5060}
# tcpenable = yes
# tcpbindaddr = 0.0.0.0:${config_asterisk_sip_port:-5060}
# transport = tcp,udp
videosupport = yes
allowguest = no
srvlookup = no

[peer](!)
type = friend
context = internal
host = dynamic
# nat = yes
disallow = all
allow = ulaw
# allow = speex
allow = h264
EOF
    chmod 640 /tmp/asterisk-sip.conf
    while read user pass
    do
        cat >>/tmp/asterisk-sip.conf <<EOF

[${user}](peer)
secret = ${pass}
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
type = transport
bind = 0.0.0.0:${config_asterisk_sip_port:-5060}
protocol = udp

[endpoint](!)
type = endpoint
context = internal
disallow = all
allow = ulaw
allow = h264

[auth](!)
type = auth
auth_type = userpass

[aor](!)
type = aor
max_contacts = 1
EOF
    chmod 640 /tmp/asterisk-pjsip.conf
    while read user pass
    do
        cat >>/tmp/asterisk-pjsip.conf <<EOF

[${user}](endpoint)
auth = ${user}
aors = ${user}

[${user}](auth)
password = ${user}
username = ${pass}

[${user}](aor)
EOF
    done
    oc_move /tmp/asterisk-pjsip.conf /etc/asterisk/pjsip.conf && rc=0
    chmod 640 /etc/asterisk/pjsip.conf
    return $rc
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
    oc_uci_merge "
package firewall

config rule 'rule_asterisk_sip'
  option name 'Allow-Asterisk-Sip'
  option src 'wan'
  option dest_port '${config_asterisk_sip_port:-5060}'
  option target 'ACCEPT'
  option proto 'udp'

config rule 'rule_asterisk_rtp'
  option name 'Allow-Asterisk-Rtp'
  option src 'wan'
  option dest_port '${config_asterisk_rtp_start:-10000}:${config_asterisk_rtp_end:-20000}'
  option target 'ACCEPT'
  option proto 'udp'
"
}

asterisk_service() {
    [ "$asterisk_need_restart" = 1 ] && oc_service restart asterisk -
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
asterisk_rtp
asterisk_firewall
asterisk_service
