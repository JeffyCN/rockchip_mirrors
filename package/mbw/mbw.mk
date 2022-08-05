################################################################################
#
# mbw
#
################################################################################

MBW_VERSION = d2cd3d36c353fee578f752c4e65a8c1efcee002c
MBW_SITE = https://github.com/raas/mbw.git
MBW_SITE_METHOD = git
MBW_LICENSE = MIT
MBW_LICENSE_FILES = LICENSE

define MBW_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D)
endef

define MBW_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/mbw $(TARGET_DIR)/usr/bin/mbw
endef

$(eval $(generic-package))
