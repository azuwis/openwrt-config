. /lib/functions.sh

oc_opkg_update() {
    if [ "$(find /var/opkg-lists/ -type f | wc -l)" -eq 0 ]; then
        echo 'opkg update'
        if [ -n "$PROXY" ]
        then
            http_proxy="$PROXY" opkg update
        else
            opkg update
        fi
    fi
}

oc_opkg_installed() {
    opkg status "$1" | grep -q installed
}

oc_opkg_install() {
    local package package_name
    for package in "$@"
    do
        package_name="$(basename "$package")"
        package_name="${package_name%.*}"
        package_name="${package_name%%_*}"
        if ! oc_opkg_installed "$package_name"; then
            oc_opkg_update
            echo "opkg install $package"
            if [ -n "$PROXY" ]
            then
                http_proxy="$PROXY" opkg install "$package"
            else
                opkg install "$package"
            fi
            if [ x"${package::1}" = x'/' ]; then
                rm -f "$package"
            fi
        fi
    done
}

oc_opkg_remove() {
    local package
    for package in "$@"
    do
        if oc_opkg_installed "$package"; then
            echo "opkg remove $package"
            opkg --autoremove remove "$package" || true
        fi
    done
}

oc_uci_exists() {
    local config
    config="$1"
    uci -q get "$config" >/dev/null
}

# XXX: not work if value contain space
oc_uci_add_list() {
    local key value
    key="$1"
    shift
    for value in "$@"
    do
        if ! uci -q -d '
' get "$key" | grep -qxF "$value"; then
            uci add_list "$key=$value"
        fi
    done
}

oc_uci_del_list() {
    local key value
    key="$1"
    shift
    for value in "$@"
    do
        uci del_list "$key=$value"
    done
}

oc_uci_set_list() {
    local config section_name list_name value
    config="$1"
    shift
    section_name="$1"
    shift
    list_name="$1"
    shift
    list_keep="$@"
    oc_uci_add_list "$config.$section_name.$list_name" "$@"
    config_cb() {
        local _type="$1"
        local _name="$2"
        if [ "$_name" = "$section_name" ]
        then
            list_cb() {
                local __name="$1"
                local __value="$2"
                if [ "$__name" = "$list_name" ]; then
                    if ! list_contains list_keep "$__value"; then
                        uci del_list "$config.$section_name.$list_name=$__value"
                    fi
                fi
            }
        else {
            list_cb() { return; }
        }
        fi
    }
    config_load "$config"
    reset_cb
}

oc_uci_commit() {
    local config
    config="$1"
    if ! oc_uci_exists "$config"; then
        return 2
    fi
    if oc_config_changed "$config"; then
        echo
        echo "uci changes:"
        if which diff >/dev/null; then
            uci export "$config" | grep -v '^package ' | diff -pu "/etc/config/$config" -
        else
            uci changes "$config"
        fi
        echo
        uci commit
        oc_update_md5sums
        return 0
    else
        rm -f "/var/.uci/$config"
        return 1
    fi
}

oc_uci_delete() {
    local config
    for config in "$@"
    do
        if oc_uci_exists "$config"; then
            uci delete "$config"
        fi
    done
}

oc_uci_del_type() {
    local config type deleted
    config="$1"
    type="$2"
    deleted="0"
    while uci -q delete "${config}.@${type}[-1]"
    do
        deleted=$((deleted+1))
    done
}

oc_uci_merge() {
    local package config changes
    package="$1"
    config="$2"
    changes="$(uci changes)"
    if [ "$(echo "$changes" | wc -l)" -gt 0 ]
    then
        echo "oc_uci_merge revert:"
        echo "$changes"
        rm -f "/var/.uci/$package"
    fi
    echo "$config" | oc_strip_comment | uci -m import "$package"
    uci show "$package" | grep "='-'$" | sed -e 's/^/delete /' -e "s/='-'$//" | uci batch
}

oc_uci_reset_section() {
    local config="$1"
    local section="$2"
    config_cb() {
        local type="$1"
        local name="$2"
        if [ "$name" = "$section" ]; then
            option_cb() {
                local option="$1"
                local value="$2"
                oc_uci_delete "$config.$section.$option"
            }
        else
            option_cb() { return 0; }
        fi
    }
    config_load "$config"
    reset_cb
}

oc_uci_keep_sections() {
    local config="$1"
    local type="$2"
    local sections_keep="$3"
    if [ "$sections_keep" = '' ]; then
        return
    fi
    config_cb() {
        local _type="$1"
        local name="$2"
        if [ "$type" = "$_type" ]; then
            if list_contains sections_keep "$name"; then
                option_cb() {
                    local option="$1"
                    local value="$2"
                    oc_uci_delete "$config.$name.$option"
                }
            else
                uci delete "$config.$name"
                option_cb() { return 0; }
            fi
        fi
    }
    config_load "$config"
    reset_cb
}

oc_uci_rename() {
    local prefix from to
    prefix="$1"
    from="$2"
    to="$3"
    if ! oc_uci_exists "$prefix.$to"; then
        uci rename "$prefix.$from=$to"
    fi
}

oc_service() {
    local action service config
    action="$1"
    service="$2"
    config="${3:-$service}"
    if [ ! -e "/etc/init.d/$service" ]; then
        return 0
    fi
    case "$action" in
        reload|restart)
            if [ x"$config" = x'-' ] || oc_uci_commit "$config"; then
                echo "service $action $service"
                "/etc/init.d/$service" "$action" || true
            fi
            ;;
        enable)
            if ! "/etc/init.d/$service" enabled; then
                echo "service $action $service"
                "/etc/init.d/$service" "$action" || true
            fi
            ;;
        disable)
            if "/etc/init.d/$service" enabled; then
                echo "service $action $service"
                "/etc/init.d/$service" "$action" || true
            fi
            ;;
        stop|start)
            "/etc/init.d/$service" "$action" 2>/dev/null || true
            ;;
        *)
            echo "service $action $service"
            "/etc/init.d/$service" "$action" || true
            ;;
    esac
}

oc_add_cron() {
    local name cron cron_file
    name="$1"
    cron="$2"
    user="${3:-root}"
    cron_file="/etc/crontabs/${user}"
    if [ ! -e "$cron_file" ] || ! grep -qxF "$cron" "$cron_file"; then
        test -e "$cron_file" && sed -i -e "/^# ${name}\$/,+1d" "$cron_file"
        echo "cron-${name}: $cron"
        echo -e "# ${name}\n${cron}" >> "$cron_file"
        /etc/init.d/cron start
    fi
}

oc_adduser() {
    local name id
    name="$1"
    id="$2"
    if ! grep -q "^${name}:" /etc/passwd
    then
        echo "Add user: $name"
        echo "${name}:x:${id}:${id}:${name}:/var/run/${name}:/bin/false" >> /etc/passwd
    fi
    if ! grep -q "^${name}:" /etc/shadow
    then
        echo "Add shadow: $name"
        echo "${name}:x:0:0:99999:7:::" >> /etc/shadow
    fi
    if ! grep -q "^${name}:" /etc/group
    then
        echo "Add group: $name"
        echo "${name}:x:${id}:${name}" >> /etc/group
    fi
}

oc_hr() {
    printf '%s\n' ------------------------------------------------------------
}

oc_md5sum_file() {
    local file
    file="$1"
    md5sum "$file" | cut -d' ' -f1
}

oc_move() {
    local src dest
    src="$1"
    dest="$2"
    if [ ! -e "$src" ]
    then
        return 1
    fi
    if [ ! -e "$dest" ] || [ x"$(oc_md5sum_file "$src")" != x"$(oc_md5sum_file "$dest")" ]; then
        echo "move: $src -> $dest"
        mv "$src" "$dest"
    else
        rm "$src"
        return 1
    fi
}

oc_remove(){
    local file
    for file in "$@"
    do
        if [ -f "$file" ]; then
            echo "remove $file"
            rm "$file"
        fi
    done
}

oc_update_md5sums() {
    oc_md5sums="$(md5sum /etc/config/*)"
}

oc_md5sum_config() {
    local config
    config="$1"
    echo "$oc_md5sums" | grep " /etc/config/${config}$" | cut -d' ' -f1
}

oc_md5sum_uci() {
    local config
    config="$1"
    uci export "$config" | grep -v '^package '| md5sum | cut -d' ' -f1
}

oc_config_changed() {
    local config
    config="$1"
    [ x"$(oc_md5sum_config "$config")" != x"$(oc_md5sum_uci "$config")" ]
}

oc_strip_comment() {
    sed -e '/^\s*$/d' -e '/^\s*#/d'
}

oc_uci_batch_set() {
    local config
    config="$1"
    echo "$config" | oc_strip_comment | sed -e 's/^/set /' | uci batch
}

oc_md5sums=''
oc_update_md5sums
