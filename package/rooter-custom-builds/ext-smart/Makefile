#Owned by DairyMan@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-smart
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-smart
  SECTION:=utils
  CATEGORY:=ROOter
  DEPENDS:=+luci +ext-rooter-basic +pingtest +ext-logo +build-admin \
		+luci-app-rootervpn +ext-wireguard \
		+bwmon +464xlat +webconsole \
		+ext-theme +luci-theme-argon \
		+ca-bundle +ca-certificates \
		+arc-storage \
		+ext-command +ext-speedtest \
		+openvpn-easy-rsa +openvpn-openssl \
		+ext-extra +luci-app-hotspot +luci-app-guestwifi \
		+usbmuxd +libusbmuxd-utils +libimobiledevice-utils +kmod-usb-net-ipheth \
		+qlog +luci-ssl +usbutils +openssl-util +ethtool \
		+nano +picocom +wget +qfirehose +ext-simplegps \
		+ext-zerotier +ext-texting +luci-app-upnp
		
  TITLE:=ROOter support for Smart routers
  PKGARCH:=all
endef

define Package/ext-smart/description
  Helper scripts to enable support for Smart routers
endef


define Build/Compile
endef

$(eval $(call BuildPackage,ext-smart))
