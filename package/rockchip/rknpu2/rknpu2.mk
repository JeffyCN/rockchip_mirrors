################################################################################
#
# rknpu2
#
################################################################################
RKNPU2_VERSION = 1.1.0
RKNPU2_SITE_METHOD = local
RKNPU2_SITE = $(TOPDIR)/../external/rknpu2
RKNPU2_INSTALL_STAGING = YES

ifeq ($(BR2_arm),y)
NPU_PLATFORM_ARCH = armhf
else
NPU_PLATFORM_ARCH = aarch64
endif

define RKNPU2_INSTALL_STAGING_CMDS
    mkdir -p $(STAGING_DIR)/usr/include/rknn
    $(INSTALL) -D -m 0644 $(@D)/Linux/librknn_api/include/rknn_api.h $(STAGING_DIR)/usr/include/rknn/rknn_api.h
endef

define RKNPU2_INSTALL_TARGET_CMDS

    cp -r $(@D)/Linux/rknn_server/${NPU_PLATFORM_ARCH}/usr/bin/* $(STAGING_DIR)/usr/bin/
    cp -r $(@D)/Linux/librknn_api/${NPU_PLATFORM_ARCH}/* $(STAGING_DIR)/usr/lib/
endef

$(eval $(generic-package))
