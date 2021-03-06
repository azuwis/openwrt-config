sysupgrade_url="https://downloads.openwrt.org/snapshots/targets/${arch_full}/openwrt-${arch_full/\//-}-${sysupgrade}-squashfs-sysupgrade.bin"
sysupgrade_img="$(basename "$sysupgrade_url")"
sysupgrade_sha="https://downloads.openwrt.org/snapshots/targets/${arch_full}/sha256sums"
download_push "$sysupgrade_url" "/tmp/${sysupgrade_img}"
download "$sysupgrade_sha" "files/tmp/${sysupgrade_img}.sha256sums"
if (cd files/tmp/; sha256sum -c --ignore-missing "${sysupgrade_img}.sha256sums"); then
    remote sysupgrade -v "/tmp/${sysupgrade_img}"
fi
