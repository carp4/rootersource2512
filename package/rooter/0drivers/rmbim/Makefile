include $(TOPDIR)/rules.mk

PKG_NAME:=umbim
PKG_RELEASE:=24

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL=$(PROJECT_GIT)/project/umbim.git
PKG_SOURCE_DATE:=2025-10-04
PKG_SOURCE_VERSION:=2939b7d019abc2be0b77eda95f66a28128cadafb
PKG_MIRROR_HASH:=6ffee42dbde6d73fde1aef80b6ef14074fbf1a2e8d86a1cce487db09b4ba3cab
PKG_MAINTAINER:=John Crispin <john@phrozen.org>

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=

PKG_FLAGS:=nonshared

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/rmbim
  SECTION:=net
  CATEGORY:=ROOter
  SUBMENU:=Drivers
  DEPENDS:=+libubox +kmod-usb-net +kmod-usb-net-cdc-mbim +wwan +luci-proto-mbim
  TITLE:=Control utility for mobile broadband modems
endef

define Package/rmbim/description
  rmbim is a command line tool for controlling mobile broadband modems using
  the MBIM-protocol.
endef

TARGET_CFLAGS += \
	-I$(STAGING_DIR)/usr/include -ffunction-sections -fdata-sections

TARGET_LDFLAGS += -Wl,--gc-sections

define Package/rmbim/install
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/umbim $(1)/sbin/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,rmbim))
