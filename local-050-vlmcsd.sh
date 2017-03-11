if [ ! -e files/vlmcsd/vlmcsd-ar71xx ]; then
    download https://github.com/Wind4/vlmcsd/releases/download/svn1107/binaries.tar.gz
    tar -xOf files/tmp/binaries.tar.gz binaries/Linux/mips/big-endian/musl/vlmcsd-mips16-openwrt-atheros-ar7xxx-ar9xxx-musl > files/vlmcsd/vlmcsd-ar71xx
    chmod +x files/vlmcsd/vlmcsd-ar71xx
fi

push files/vlmcsd/init /etc/init.d/vlmcsd
push files/vlmcsd/keep /lib/upgrade/keep.d/vlmcsd

case "$arch" in
    ar71xx)
        if ! push "files/vlmcsd/vlmcsd-$arch" /usr/bin/vlmcsd; then
            remote /etc/init.d/vlmcsd stop
            push "files/vlmcsd/vlmcsd-$arch" /usr/bin/vlmcsd
        fi
        ;;
esac
