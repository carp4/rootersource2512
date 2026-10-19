#Owned by DairyMan@Whirlpool
# 
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-wizardw
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by DM/makefile by Cobia@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-wizardw
  SECTION:=utils
  CATEGORY:=ROOter
  SUBMENU:=Optional Applications
  TITLE:=support for wizard
  PKGARCH:=all
endef

define Package/ext-wizardw/description
  Helper scripts to add wizard
endef


define Build/Compile
endef

define Package/ext-wizardw/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,ext-wizardw))
