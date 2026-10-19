#
# Copyright (C) 2017 Dan Luedtke <mail@danrl.com>
#
# This is free software, licensed under the GNU General Public License v2.

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for the MWAN3 MultiWAN Manager
LUCI_DEPENDS:=+luci-base +mwan3
PKG_LICENSE:=GPL-2.0

PKG_MAINTAINER:=Florian Eckert <fe@dev.tdt.de>

# Local fix: root/usr/libexec/luci-mwan3 now selects `ip -6 rule` / `ip -6
# route list table N` for mwan3 interfaces with family=ipv6. Upstream always
# used the IPv4-only forms, so LuCI -> mwan3 -> Diagnostics reported phantom
# "missing fwmark/iif rule" and "routing table not found" for every wan<N>_6
# member even when IPv6 was working. luci.mk derives PKG_VERSION from git, so
# bump PKG_RELEASE (default 1) to give the rebuilt ipk a distinct version and
# force a reinstall over the stock file.
PKG_RELEASE:=2

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature
