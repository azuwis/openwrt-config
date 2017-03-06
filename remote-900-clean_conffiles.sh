find /etc/config/ -type f -name '*-opkg' -exec echo remove '{}' ';'
find /etc/config/ -type f -name '*-opkg' -exec rm '{}' ';'
if [ -d /etc/unbound/ ]
then
    find /etc/unbound/ -type f -name '*-opkg' -exec echo remove '{}' ';'
    find /etc/unbound/ -type f -name '*-opkg' -exec rm '{}' ';'
fi
