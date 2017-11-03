oc_opkg_install watchcat

if [ -f /etc/uci-defaults/50-watchcat ]; then
    echo 'import /etc/uci-defaults/50-watchcat'
    sh /etc/uci-defaults/50-watchcat >/dev/null
    rm /etc/uci-defaults/50-watchcat
fi
uci batch <<EOF
set system.@watchcat[0].forcedelay='30'
set system.@watchcat[0].mode='ping'
set system.@watchcat[0].period='2h'
set system.@watchcat[0].pinghosts="$config_watchcat_pinghosts"
EOF

if ! grep -q 'kill -KILL' /etc/init.d/watchcat; then
    echo 'patch /etc/init.d/watchcat'
    sed -i 's/kill "$pid"/kill -KILL "$pid"/' /etc/init.d/watchcat
    oc_service restart watchcat -
fi

oc_service restart watchcat system
