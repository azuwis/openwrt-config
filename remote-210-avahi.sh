oc_opkg_install avahi-nodbus-daemon
cat >/tmp/avahi-daemon.conf <<EOF
[server]
browse-domains=local
use-ipv6=no

[publish]
disable-publishing=yes

[reflector]
enable-reflector=yes

[rlimits]
rlimit-core=0
rlimit-data=4194304
rlimit-fsize=0
rlimit-nofile=30
rlimit-stack=4194304
rlimit-nproc=3
EOF
oc_move /tmp/avahi-daemon.conf /etc/avahi/avahi-daemon.conf && oc_service restart avahi-daemon -
