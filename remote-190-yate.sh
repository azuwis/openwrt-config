yate_packages() {
    oc_opkg_install yate yate-mod-ysipchan yate-mod-yrtpchan yate-mod-regfile yate-mod-regexroute
}

yate_ysipchan() {
    cat >/tmp/yate-ysipchan.conf <<EOF
[general]
port=${config_yate_sip_port:-5060}
# forward_sdp=yes

[codecs]
h263=yes
# vp8=yes
# vp8/90000=yes
EOF
    oc_move /tmp/yate-ysipchan.conf /etc/yate/ysipchan.conf && yate_need_restart=1
}

yate_yrtpchan() {
    cat >/tmp/yate-yrtpchan.conf <<EOF
[general]
minport=${config_yate_rtp_minport:-10000}
maxport=${config_yate_rtp_maxport:-20000}
EOF
    oc_move /tmp/yate-yrtpchan.conf /etc/yate/yrtpchan.conf && yate_need_restart=1
}

yate_regfile() {
    local rc=1
    local user pass
    cat >/tmp/yate-regfile.conf <<'EOF'
[general]
; route=100
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
  option proto 'udp'

config rule 'rule_yate_rtp'
  option name 'Allow-Yate-Rtp'
  option src 'wan'
  option dest_port '${config_yate_rtp_minport:-10000}:${config_yate_rtp_maxport:-20000}'
  option target 'ACCEPT'
  option proto 'udp'
"
}

yate_service() {
    [ "$yate_need_restart" = 1 ] && oc_service restart yate -
}

yate_need_restart=0
yate_packages
yate_ysipchan
yate_yrtpchan
echo "$config_yate_users" | oc_strip_comment | yate_regfile && yate_need_restart=1
yate_regexroute
yate_firewall
yate_service