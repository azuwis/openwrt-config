oc_opkg_install unbound-daemon >/dev/null 2>&1
cat >/tmp/unbound.conf <<EOF
server:
  username: unbound
  num-threads: 1
  msg-cache-slabs: 1
  rrset-cache-slabs: 1
  infra-cache-slabs: 1
  key-cache-slabs: 1

  verbosity: 1
  statistics-interval: 0
  statistics-cumulative: no
  extended-statistics: no

  edns-buffer-size: 1280
  msg-buffer-size: 8192
  port: 5453
  tcp-upstream: ${config_unbound_tcp}
  outgoing-port-permit: 10240-65535

  harden-short-bufsize: yes
  harden-large-queries: yes
  harden-glue: yes
  harden-below-nxdomain: no
  harden-referral-path: no
  use-caps-for-id: no

  use-syslog: yes
  chroot: "/var/lib/unbound"
  directory: "/var/lib/unbound"
  pidfile: "/var/run/unbound.pid"

  outgoing-range: 64
  num-queries-per-thread: 32
  outgoing-num-tcp: 1
  incoming-num-tcp: 1
  rrset-cache-size: 256k
  msg-cache-size: 128k
  key-cache-size: 128k
  neg-cache-size: 64k
  infra-cache-numhosts: 256

  module-config: "iterator"

  qname-minimisation: yes
  prefetch: no
  prefetch-key: no
  target-fetch-policy: "0 0 0 0 0"

  cache-min-ttl: 120
  cache-max-ttl: 36000
  cache-max-negative-ttl: 0
  val-bogus-ttl: 300
  infra-host-ttl: 900

forward-zone:
  name: "."
  forward-addr: ${config_unbound_forwarder}
EOF
uci batch <<EOF
set unbound.@unbound[0].listen_port='5453'
set unbound.@unbound[0].manual_conf='1'
set unbound.@unbound[0].query_minimize='1'
set unbound.@unbound[0].resource='tiny'
EOF
oc_service restart unbound
if oc_move /tmp/unbound.conf /etc/unbound/unbound.conf; then
    oc_service restart unbound - 2>/dev/null
fi
