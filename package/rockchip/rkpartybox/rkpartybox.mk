################################################################################
#
# rkpartybox
#
################################################################################

RKPARTYBOX_SITE = $(TOPDIR)/../app/rkpartybox
RKPARTYBOX_SITE_METHOD = local

RKPARTYBOX_LICENSE = ROCKCHIP
RKPARTYBOX_LICENSE_FILES = LICENSE

RKPARTYBOX_DEPENDENCIES += libdrm wpa_supplicant lvgl lv_drivers bluez5_utils
RKPARTYBOX_CONF_OPTS += -DLV_USE_DEMO_MUSIC=1

ifeq ($(BR2_PACKAGE_RK3308_CORE_BOARD),y)
RKPARTYBOX_CONF_OPTS += -DRK3308_PBOX_CORE_BOARD=TRUE
endif

define RKPARTYBOX_POST_INSTALL_TO_TARGET
	$(INSTALL) -D -m 0755 $(@D)/lib64/lib* $(TARGET_DIR)/usr/lib/
endef
#RKPARTYBOX_POST_INSTALL_TARGET_HOOKS += RKPARTYBOX_POST_INSTALL_TO_TARGET

$(eval $(cmake-package))
