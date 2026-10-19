#
# Z8102AX V2 image defaults
#
# A small, self-contained set of /etc/uci-defaults scripts that bake this
# project's configuration choices into the firmware, so a clean
#
#     sysupgrade -n
#
# leaves a box that is already configured and needs nothing afterwards. There is
# no "restore config" step and no post-flash editing: everything these scripts
# set is a default that the image ships with.
#
# This is NOT a config overlay and NOT a `-b`/custom-config build path. The
# build stays the plain ROOter template:
#
#     ./build Z8102TEST
#
# The package is selected by one line in
# configfiles/template/.config_z8102test (CONFIG_PACKAGE_z8102-defaults=y),
# which is where package selection belongs -- the same place every other
# ROOter package is chosen from.
#
# Why a separate package rather than more files inside ROOter's
# ext-rooter-basic: these are this project's defaults, not ROOter's, and
# keeping them separate means the diff against stock ROOter is one directory
# rather than changes sprinkled through a vendor package that ROOter ships
# upstream.
#
# Where it runs: /etc/init.d/boot (START=10) calls uci_apply_defaults, which
# is BEFORE /etc/init.d/rooter (START=30) where ROOter's initialize.sh runs.
# That ordering is load-bearing in two places:
#   * 90-system-config sets the hostname, and initialize.sh only renames the
#     box while it is still called "OpenWrt", so the name set here survives.
#   * 93-firewall-config deliberately does NOT set the wan zone's network list.
#     initialize.sh's do_zone() rebuilds that list at boot from maxmodem and
#     restarts the firewall if it changed, so anything set here would only be
#     overwritten.
#
# Contents, and why each script is here at all:
#
#   90-system-config   hostname, timezone, log levels. Everything else the
#                      25.12 gold had in it is gone: its USB-modem LED triggers
#                      named `blue:usb-0` / `blue:usb-1`, and this board's
#                      device tree declares only reset, wps, red:status,
#                      green:status, blue:status, modem1:status, modem2:status
#                      (target/linux/mediatek/dts/mt7981b-zbt-z8102ax.dtsi).
#                      There is no such LED on it.
#
#   92-dhcp-dnsmasq   dnsmasq A/AAAA filtering off, and the LAN RA server
#                      enabled. Nothing else in the tree sets these: ROOter's
#                      initialize.sh never touches the dhcp config, and 24.10's
#                      config_generate only sets network.lan.ip6assign and
#                      friends, not odhcpd's RA behaviour or dnsmasq's filters.
#
#   93-firewall-config flow offload, and a tailscale zone/interface that is
#                      ready before tailscale is joined. Non-destructive: it
#                      creates and sets, it never deletes. See the script header
#                      for why the previous wipe-and-rebuild was wrong.
#
# What is deliberately NOT here, and why -- these were all in the 25.12 gold:
#
#   91-network-config  hardcoded network.wan1.device='usb0' / wan2='usb1'.
#                      Wrong device naming for ROOter: initialize.sh deletes and
#                      recreates network.wan1..wan$maxmodem itself, with
#                      device="wan$N" (ROOter netdev naming), 20s after these
#                      scripts run. Its wan6 block is redundant too -- 24.10's
#                      config_generate already creates network.wan6
#                      (eth1, dhcpv6, reqprefix 60, norelease 1, metric 1) --
#                      as are the lan ip6assign/ip6hint/ip6class/multipath
#                      options it sets.
#
#   94-mwan3-config    wiped /etc/config/mwan3 and rebuilt SIX members (the
#                      two-modem 25.12 shape). The tree already ships
#                      feeds/packages/net/mwan3/files/etc/config/mwan3 with
#                      TWENTY-TWO, the correct default policy applied, and the
#                      uniform-2 flush policy on every member. Porting this
#                      would have deleted wan3/4/5, the five CLAT companions,
#                      wwan2/wwan26, wwan5/wwan56 and wg0. The three genuine
#                      divergences from our verified deployment (rules pointing
#                      at failover instead of balanced; wan1-5 initial_state
#                      offline instead of online; explicit sticky 0) are fixed
#                      in that file instead. See NOTES.md.
#
#   98-mwan3-diag-fix  byte-identical to what the tree already carries at
#                      feeds/luci/applications/luci-app-mwan3/root/usr/libexec/
#                      luci-mwan3 (commit 9393c6a4).
#
#   99-wireless-config ROOter overrides /sbin/wifi itself. Its wifi_config()
#                      runs ucode /usr/share/hostap/wifi-detect.uc, which
#                      enumerates wiphys from the running kernel over nl80211
#                      (nl.request(NL80211_CMD_GET_WIPHY, NLM_F_DUMP)), then
#                      /lib/wifi/mac80211.uc builds the sections, then ROOter
#                      sets disabled=0 noscan=1 country=US txpower=20, SSID
#                      ROOter / "ROOter 5G", encryption=psk2, key=rooter2017,
#                      channel 36->44. wlan.defaults and board.json are only
#                      optionally read and are not required. So WiFi comes up
#                      on first boot unaided, and a script forcing country=PA,
#                      SSID=OpenWrt and htmode=HE20 would fight it.
#
#   89-pd-default-fix  already in the tree, generalised, as
#                      ext-rooter-basic/files/etc/hotplug.d/iface/99-pd-default.sh
#                      (self-scaling; no hardcoded interface list).
#
#   88-create-modem-links, 99-gps-default, 99-qmodem-dial-off
#                      qmodem/LettucePi-era artifacts. ROOter creates its own
#                      modem links and ships its own GPS support; this is a
#                      modem-only device on stock ROOter and those never belong
#                      in one of its builds.
#
#   95-routing-tables  named diagnostic routes. Cosmetic, not configuration,
#                      and the table numbers depend on the live mwan3 state.
#
#   97-gui-password    private. Absolutely not in a shareable image.
#
# Privacy: nothing in this package, and nothing in the resulting image, may
# contain a Tailscale/CGNAT address, a device nickname, a join/auth key, or
# any credential. tailscale is installed but never joined.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=z8102-defaults
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only

PKG_MAINTAINER:=

# PKGARCH is set inside the Package/ define below, NOT here. See the comment
# there for why the position is load-bearing.
include $(INCLUDE_DIR)/package.mk

define Package/z8102-defaults
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Z8102AX V2 image defaults (uci-defaults)

  # Arch-independent: nothing is compiled, the payload is three shell scripts.
  # Without this the ipk is named z8102-defaults_1.0-r1_aarch64_cortex-a53.ipk
  # and carries `Architecture: aarch64_cortex-a53`, i.e. one identical copy per
  # target architecture, none of them `_all`.
  #
  # It MUST be set here rather than at the top of the file. Setting PKGARCH
  # before `include $(INCLUDE_DIR)/package.mk` has no effect: that include pulls
  # in package-defaults.mk, whose lines 39-43 unconditionally reassign
  #
  #     ifneq ($(ARCH_PACKAGES),)
  #       PKGARCH:=$(ARCH_PACKAGES)
  #     else
  #       PKGARCH:=$(BOARD)
  #     endif
  #
  # clobbering whatever was set beforehand. A define block is expanded later, so
  # a value here survives. This is why every other ROOter config-only package
  # (ext-rooter-basic, ext-rooter16, package/rooter/0routerspecfic/*) places its
  # PKGARCH inside its Package/ define.
  PKGARCH:=all

  # Deliberately minimal, and deliberately NOT depending on mwan3.
  #
  #  * No +mwan3. None of these three scripts need mwan3 to be installed --
  #    they touch system, dhcp and firewall only. And ./build Z8102TEST emits
  #    TWO images from one package set: the base (ext-rooter-lite) and the
  #    MWAN3 variant (ext-rooter16, which is what pulls mwan3 in via
  #    +luci-app-mwan3). A hard +mwan3 here would force the dependency to be
  #    satisfied in the base pass too, dragging mwan3 into the non-MWAN3 image
  #    and defeating the split.
  #
  #  * +odhcpd-ipv6only, not +odhcpd. The template selects
  #    CONFIG_PACKAGE_odhcpd-ipv6only=y and leaves CONFIG_PACKAGE_odhcpd not
  #    set; depending on the wrong variant installs both and conflicts. It is
  #    odhcpd-ipv6only that serves the RAs and stateless DHCPv6 that
  #    92-dhcp-dnsmasq configures (dhcp.lan.ra / ra_slaac / ra_default /
  #    ra_flags / dhcpv6=server).
  #
  #  * +dnsmasq, not +dnsmasq-full. filter_a / filter_aaaa are core dnsmasq
  #    options, present in the plain variant. dnsmasq-full is not set in the
  #    template either -- only the MWAN3 image picks it up, via
  #    luci-app-dnsmasq-ipset.
  DEPENDS:= \
	+firewall4 \
	+dnsmasq \
	+odhcpd-ipv6only \
	+uci
endef

define Package/z8102-defaults/description
  /etc/uci-defaults scripts that bake this project's configuration into the
  Z8102AX V2 firmware, so a clean "sysupgrade -n" leaves a configured box with
  no post-flash step. Built with the plain ROOter template; selected by
  CONFIG_PACKAGE_z8102-defaults=y in configfiles/template/.config_z8102test.
endef

# There is nothing to compile. This override is REQUIRED, not an optimisation:
# without it, package.mk's default Build/Compile runs
#
#     $(MAKE) -C $(PKG_BUILD_DIR)
#
# and PKG_BUILD_DIR is empty for a source-less package, so make stops with
#
#     make[4]: *** No targets specified and no makefile found.  Stop.
#     make[3]: *** [Makefile:177: .../z8102-defaults-1.0/.built] Error 2
#     ERROR: package/z8102-defaults failed to build.
#
# which aborts `make world` and takes the whole firmware build down with it.
# Every source-less package in this tree defines an empty Build/Compile for
# exactly this reason -- see package/rooter/0routerspecfic/z8102v2/Makefile and
# package/rooter/ext-rooter-basic/Makefile.
define Build/Compile
endef

define Package/z8102-defaults/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/* $(1)/etc/uci-defaults/
endef

$(eval $(call BuildPackage,z8102-defaults))