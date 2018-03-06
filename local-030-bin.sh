remote mkdir -p /etc/profile.d/
remote mkdir -p /root/bin/

push files/bin/keep /lib/upgrade/keep.d/oc-bin
push files/bin/profile.sh /etc/profile.d/oc-bin.sh

push files/bin/ipcn /root/bin/ipcn
push files/bin/ipinfo /root/bin/ipinfo
push files/bin/lrcc /root/bin/lrcc
