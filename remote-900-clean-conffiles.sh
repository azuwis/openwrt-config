find /etc/config/ /etc/unbound/ -type f -name '*-opkg' -exec echo remove '{}' ';'
find /etc/config/ /etc/unbound/ -type f -name '*-opkg' -exec rm '{}' ';'
