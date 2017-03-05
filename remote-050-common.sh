oc_opkg_install $config_packages

uci batch <<EOF
set system.@system[0].timezone='CST-8'
set system.@system[0].zonename='Asia/Shanghai'
EOF
oc_uci_batch_set "$config_common"
oc_service reload system

uci set system.@system[0].log_buffer_size='256'
oc_service reload log system

oc_uci_delete system.ntp.server
oc_uci_add_list system.ntp.server 0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org
oc_service restart sysntpd system

uci set dhcp.@dnsmasq[0].cachesize=1024
oc_uci_add_list dhcp.@dnsmasq[0].bogusnxdomain 122.229.30.202 60.191.124.236

# oc_uci_del_type dhcp host
dhcp_host() {
    local ip mac
    all_names=''
    while read ip mac
    do
        local name="${ip//./_}"
        all_names="$all_names $name"
        oc_uci_reset_section dhcp "$name"
        uci set "dhcp.${name}=host"
        uci set "dhcp.${name}.ip=${ip}"
        uci set "dhcp.${name}.mac=${mac}"
    done
    oc_uci_keep_sections dhcp host "$all_names"
}
echo "$config_dhcp_host" | oc_strip_comment | dhcp_host

oc_service reload dnsmasq dhcp

if [ x"$config_root_password" != x ] && ! grep -qF "root:$config_root_password" /etc/shadow; then
    echo "change root password"
    awk -F":" 'BEGIN{OFS=":"}{if($1 == "root"){$2="'$config_root_password'"}; print}' /etc/shadow > /tmp/shadow
    mv /tmp/shadow /etc/shadow
    chmod 600 /etc/shadow
fi

if [ -f /etc/dropbear/authorized_keys ]; then
    uci batch <<EOF
set dropbear.@dropbear[0].PasswordAuth='off'
set dropbear.@dropbear[0].RootPasswordAuth='off'
EOF
    oc_service reload dropbear
fi

oc_service stop telnetd
oc_service disable telnetd
