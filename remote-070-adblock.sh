oc_opkg_install adblock ca-bundle libustream-openssl

uci set "adblock.global.adb_enabled=1"
if grep -q '^#' /etc/config/adblock
then
    uci commit
    oc_service restart adblock -
else
    oc_service restart adblock
fi

oc_add_cron adblock '0 4 * * * /etc/init.d/adblock start'
