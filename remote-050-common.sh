oc_opkg_install $config_packages_common
oc_opkg_install $config_packages

oc_uci_rename system @system[0] system
uci batch <<EOF
set system.system.timezone='CST-8'
set system.system.zonename='Asia/Shanghai'
EOF
oc_service reload system
oc_uci_merge "$config_system"

uci set system.system.log_buffer_size='256'
oc_service reload log system

cat >/tmp/sysctl.conf <<EOF
net.netfilter.nf_conntrack_max=32768
EOF
if oc_move /tmp/sysctl.conf /etc/sysctl.conf
then
    oc_service restart sysctl - 2>/dev/null
fi

oc_uci_set_list system ntp server 0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org
oc_service restart sysntpd system

uci set dhcp.@dnsmasq[0].cachesize=1024
uci set dhcp.@dnsmasq[0].localuse=1
oc_uci_add_list dhcp.@dnsmasq[0].bogusnxdomain 122.229.30.202 60.191.124.236

# oc_uci_del_type dhcp host
dhcp_host_clean() {
    local ip mac all_names name
    all_names=''
    while read ip mac
    do
        name="${ip//./_}"
        all_names="$all_names $name"
    done
    oc_uci_keep_sections dhcp host "$all_names"
}
dhcp_host_apply() {
    local ip mac name
    while read ip mac
    do
        name="${ip//./_}"
        uci set "dhcp.${name}=host"
        uci set "dhcp.${name}.ip=${ip}"
        uci set "dhcp.${name}.mac=${mac}"
    done
}
if [ -n "$CLEANUP" ]
then
    echo "$config_dhcp_host" | oc_strip_comment | dhcp_host_clean
fi
echo "$config_dhcp_host" | oc_strip_comment | dhcp_host_apply

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
