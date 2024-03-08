# Rockchip's pcba porting for Linux


PCBA_SITE = $(TOPDIR)/../external/rk_pcba_test
PCBA_SITE_METHOD = local

ifeq ($(BR2_PACKAGE_PX3SE),y)
ifeq ($(BR2_PACKAGE_PCBA_SCREEN),y)
PCBA_CONF_OPTS = -DPCBA_WITH_UI=ON
PCBA_DEPENDENCIES = zlib libpthread-stubs libpng libdrm
endif

PCBA_CONF_OPTS += -DPCBA_PX3SE=ON
endif

ifeq ($(BR2_PACKAGE_RK3308),y)
PCBA_CONF_OPTS = -DPCBA_3308=ON
endif

ifeq ($(BR2_PACKAGE_RK3229GVA),y)
PCBA_CONF_OPTS = -DPCBA_3229GVA=ON
endif

ifeq ($(BR2_PACKAGE_RK1808), y)
PCBA_CONF_OPTS= -DPCBA_1808=ON
endif

ifeq ($(BR2_PACKAGE_RK3326), y)
PCBA_CONF_OPTS= -DPCBA_3326=ON
endif

ifeq ($(BR2_PACKAGE_PX30), y)
PCBA_CONF_OPTS= -DPCBA_PX30=ON
endif

ifeq ($(BR2_PACKAGE_RK3288), y)
PCBA_CONF_OPTS= -DPCBA_3288=ON
endif

ifeq ($(BR2_PACKAGE_RK3328), y)
PCBA_CONF_OPTS= -DPCBA_3328=ON
endif

ifeq ($(BR2_PACKAGE_RK3399), y)
PCBA_CONF_OPTS= -DPCBA_3399=ON
endif

ifeq ($(BR2_PACKAGE_RK3399PRO), y)
PCBA_CONF_OPTS= -DPCBA_3399PRO=ON
endif

ifeq ($(BR2_PACKAGE_RV1126_RV1109), y)
PCBA_CONF_OPTS= -DPCBA_1126_1109=ON
endif

ifeq ($(BR2_PACKAGE_RK3566_RK3568), y)
PCBA_CONF_OPTS= -DPCBA_356X=ON
endif

ifeq ($(BR2_PACKAGE_RK3588), y)
PCBA_CONF_OPTS= -DPCBA_3588=ON
endif

define PCBA_INSTALL_INIT_SYSV
$(INSTALL) -d -m 0755 $(TARGET_DIR)/data
$(INSTALL) -D -m 0755 $(@D)/rk_pcba_test/* $(TARGET_DIR)/data
endef

$(eval $(cmake-package))
