#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-rooter-basic
PKG_VERSION:=4.500
# r10: /etc/hotplug.d/iface/50-z8102-wan6-mwan3 generalized to every enabled
# ipv6 mwan3 member, with withdrawal handling. Bumped because the package
# gains a new installed file -- without this the ipk keeps the same version
# with different contents and opkg will not upgrade an existing install.
# r11: two changes to /etc/hotplug.d/iface/50-z8102-wan6-mwan3, both needed.
#   (1) It no longer restarts mwan3 on an ipv6 rotation. The restart was global
#       (this mwan3 has no per-member restart, and reload == stop; start), so it
#       reset every member to its initial_state and put the ipv4 legs offline
#       for ~50s -- an ipv6 event breaking ipv4. The tracker re-derives its own
#       source (refresh_src_ip), so the hotplug now only records the change, and
#       only ever cycles an interface on withdrawal.
#   (2) The ACTION gate was widened from ACTION=ifupdate alone to
#       ifup|connected|ifupdate. ifupdate is real (netifd emitted it twice for
#       wan2_6 during a live rotation on 2026-10-02) but it only ever fires on a
#       ROTATION. A WITHDRAWAL -- interface up, global address gone, the actual
#       outage -- emits ifdown->ifup->connected and NO ifupdate, so the old gate
#       saw nothing and the withdrawal branch was unreachable. ifdown and
#       disconnected stay excluded: the withdrawal branch cycles the interface
#       back UP, so reacting to a way-down event would fight a shutdown.
# r12: adds /etc/hotplug.d/iface/99-pd-default.sh, a new installed file. This
#     installs a PLAIN (non-source-locked) ipv6 default route alongside the ones
#     odhcp6c creates, so LAN clients holding ULA addresses get ipv6 egress via
#     NAT66. odhcp6c only creates `default from <modem /64>:: via <gw> metric
#     512`, which matches nothing a LAN client sends, so client v6 traffic dies
#     while the uplink looks healthy. Ported from the z8102-custom-config gold
#     (89-pd-default-fix) but NOT verbatim: the gold hardcodes three
#     interface->device pairs for a fixed two-modem layout, and ROOter pins
#     maxmodem=4 when mwan3 is present, so wan3_6/wan4_6 would be silently
#     skipped. This derives the device from whichever interface actually
#     carries an ipv6 default, so it self-scales. Also bumped because a new
#     installed file at an unchanged version leaves the ipk looking identical to
#     opkg and it will not upgrade an existing install.
# Bumped because the installed file changed contents and opkg will not upgrade
# an existing install at the same version.
# r13: two changes, both shipping-image defaults rather than code.
#   (1) /etc/config/maxmodem now ships maxmodem '5' with custom '1'. 5 is the
#       hard ceiling of ROOter's own GUI (multimodem.htm offers 1-5 and nothing
#       else), and 5 modem members is what the shipped /etc/config/mwan3
#       declares. The 'custom' flag is the load-bearing part: initialize.sh's
#       firstboot() overwrites maxmodem to 4 whenever /etc/config/mwan3 exists
#       UNLESS custom == 1, so shipping 5 alone would silently become 4 on the
#       first boot after a clean flash and wan5/wan5_6 would never be enabled.
#       Nothing else in the tree reads 'custom' -- it exists only to suppress
#       that auto-derivation. This also invalidates the r12 note above: ROOter no
#       longer pins maxmodem to 4, so 99-pd-default.sh's self-scaling device
#       derivation is now exercised over 5 modems rather than 4.
#   (2) /etc/hotplug.d/iface/10-lan strips a prefix length off network.lan.ipaddr
#       before writing dnsmasq's address=/rooter.local/ line. 24.10's
#       config_generate writes the address bare, so this is hardening rather
#       than a fix for a clean flash -- but a config that came in with a
#       "192.168.1.1/24" made dnsmasq refuse to start ("Bad address in
#       --address"), taking the resolver down with it. Also guards an empty
#       ipaddr, which would otherwise write the same broken line.
PKG_RELEASE:=13

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

# +kmod-rt2800-usb

define Package/ext-rooter-basic
  SECTION:=utils
  CATEGORY:=ROOter
  SUBMENU:=Basic Support
  DEPENDS:=+luci-compat +kmod-usb-net +kmod-usb-net-huawei-cdc-ncm +kmod-usb-net-cdc-ether +kmod-usb-acm \
	    +kmod-usb-net-qmi-wwan  +kmod-usb-net-rndis +kmod-usb-serial-qualcomm \
	    +kmod-usb-net-sierrawireless +kmod-usb-ohci +kmod-usb-serial +kmod-nls-utf8 \
	    +kmod-usb-serial-option +kmod-usb-serial-sierrawireless +luci-proto-3x \
	    +kmod-usb-uhci +kmod-usb2 +luci-proto-3g +iptables-nft +ip6tables-nft \
	    +usb-modeswitch +wireless-tools +rmbim +rqmi +ext-sms +ext-buttons +kmod-rt2800-usb +xxd +kmod-tcp-bbr +kmod-usb3 
  TITLE:=ROOter support for usbmodems
  PKGARCH:=all
endef

define Package/ext-rooter-basic/description
  Helper scripts to enable ROOter to manage usb modem interfaces
endef


define Build/Compile
endef

define Package/ext-rooter-basic/install
	$(CP) ./files/* $(1)/


endef

$(eval $(call BuildPackage,ext-rooter-basic))
