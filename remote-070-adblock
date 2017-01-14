oc_opkg_install adblock

uci set "adblock.global.adb_fetch=/bin/uclient-fetch"
uci set "adblock.global.adb_fetchparm=-q --timeout=5 -O"
oc_service restart adblock

oc_add_cron adblock '0 4 * * * /etc/init.d/adblock start'
