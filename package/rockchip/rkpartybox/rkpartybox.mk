################################################################################
#
# rkpartybox
#
################################################################################

RKPARTYBOX_SITE = $(TOPDIR)/../app/rkpartybox
RKPARTYBOX_SITE_METHOD = local
RKPARTYBOX_DEPENDENCIES += rkwifibt-app libdrm
RKPARTYBOX_CONF_OPTS += -DLV_USE_DEMO_MUSIC=1

define RKPARTYBOX_POST_INSTALL_TO_TARGET
	$(INSTALL) -D -m 0755 $(@D)/lib64/lib* $(TARGET_DIR)/usr/lib/
endef
RKPARTYBOX_POST_INSTALL_TARGET_HOOKS += RKPARTYBOX_POST_INSTALL_TO_TARGET

$(eval $(cmake-package))
