oc_opkg_install adblock ca-bundle libustream-openssl

# uci set "adblock.global.adb_enabled=1"
# oc_service restart adblock

oc_add_cron adblock '0 4 * * * /etc/init.d/adblock start'
