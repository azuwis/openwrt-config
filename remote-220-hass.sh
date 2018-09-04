oc_opkg_install rpcd uhttpd uhttpd-mod-ubus

oc_uci_rename rpcd @login[0] hass
uci commit

oc_uci_merge "
package rpcd

config login 'hass'
  option username 'hass'
  option password '${config_hass_password}'
  list read '-'
  list read 'hass'
  list read 'unauthenticated'
  list write '-'
"

cat >/tmp/hass.json <<'EOF'
{
  "hass": {
    "description": "Hass user access role",
    "read": {
      "ubus": {
        "hostapd.*": [ "get_clients" ]
      }
    }
  }
}
EOF
oc_move /tmp/hass.json /usr/share/rpcd/acl.d/hass.json
