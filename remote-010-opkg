if grep -qxF "DISTRIB_ID='OpenWrt'" /etc/openwrt_release; then
   if grep -qF downloads.openwrt.org /etc/opkg/distfeeds.conf; then
       echo 'patch /etc/opkg/distfeeds.conf'
       sed -i -e 's/downloads\.openwrt\.org/openwrt.mirrors.ustc.edu.cn/' /etc/opkg/distfeeds.conf
   fi
fi
