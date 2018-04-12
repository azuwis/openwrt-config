oc_opkg_install acme

oc_uci_rename acme @acme[0] acme
oc_uci_delete acme.example
oc_service reload acme

chmod 750 /etc/acme

oc_uci_merge "$config_acme"
