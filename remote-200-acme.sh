oc_opkg_install acme

oc_uci_rename acme @acme[0] acme
oc_uci_delete acme.example
oc_service reload acme

acme_account() {
    local line key account='/etc/acme/account.conf'
    while read -r line
    do
        key="${line%%=*}"
        if grep -qFx "$line" "$account"
        then
            continue
        else
            if grep -q "^${key}=" "$account"
            then
                sed -i "s/^${key}=.*/${line}/" "$account"
            else
                echo "$line" >> "$account"
            fi
        fi
    done
}
[ -e /etc/acme/account.conf ] || touch /etc/acme/account.conf
chmod 750 /etc/acme
chmod 640 /etc/acme/account.conf
echo "$config_acme_account" | oc_strip_comment | acme_account

oc_uci_merge "$config_acme"
