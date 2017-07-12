oc_opkg_install kcptun

oc_uci_batch_set "$config_kcptun"
oc_uci_add_list kcptun.shadowsocks.extra_params crypt=none datashard=10 parityshard=3

oc_service restart kcptun
