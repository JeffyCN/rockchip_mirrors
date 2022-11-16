################################################################################
#
# rknpu2
#
################################################################################
RKNPU2_VERSION = 1.0.0
RKNPU2_SITE_METHOD = local
RKNPU2_SITE = $(TOPDIR)/../external/rknpu2
RKNPU2_INSTALL_STAGING = YES

RKNPU2_LICENSE = ROCKCHIP
RKNPU2_LICENSE_FILES = LICENSE

ifeq ($(BR2_arm),y)
GCC_TYPE=arm-none-linux-gnueabihf
EXPORT_PATH=$(PATH):$(TOPDIR)/../prebuilts/gcc/linux-x86/arm/gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf/bin
NPU_PLATFORM_ARCH = armhf
else
GCC_TYPE=aarch64-none-linux-gnu
EXPORT_PATH=$(PATH):$(TOPDIR)/../prebuilts/gcc/linux-x86/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin
NPU_PLATFORM_ARCH = aarch64
endif

ifeq ($(BR2_PACKAGE_RK356X),y)
NPU_PLATFORM_INFO = RK356X
NPU_DEMO_BUILD = build-linux_RK356X.sh
endif

ifeq ($(BR2_PACKAGE_RK3588), y)
NPU_PLATFORM_INFO = RK3588
NPU_DEMO_BUILD = build-linux_RK3588.sh
endif

define RKNPU2_BUILD_CMDS
	cd $(@D)/examples/rknn_common_test && export PATH=$(EXPORT_PATH) && export GCC_COMPILER=$(GCC_TYPE) && ./$(NPU_DEMO_BUILD)
endef

define RKNPU2_INSTALL_STAGING_CMDS
	mkdir -p $(STAGING_DIR)/usr/include/rknn
	$(INSTALL) -D -m 0644 $(@D)/runtime/$(NPU_PLATFORM_INFO)/Linux/librknn_api/include/rknn_api.h ${TARGET_DIR}/usr/include/rknn/rknn_api.h
endef

define RKNPU2_INSTALL_TARGET_CMDS
	cp -r $(@D)/runtime/$(NPU_PLATFORM_INFO)/Linux/rknn_server/${NPU_PLATFORM_ARCH}/usr/bin/* ${TARGET_DIR}/usr/bin/
	cp -r $(@D)/runtime/$(NPU_PLATFORM_INFO)/Linux/librknn_api/${NPU_PLATFORM_ARCH}/* ${TARGET_DIR}/usr/lib/
	$(INSTALL) -D -m 0755 $(@D)/examples/rknn_common_test/install/rknn_common_test_Linux/rknn_common_test ${TARGET_DIR}/usr/bin/
	cp -r $(@D)/examples/rknn_common_test/install/rknn_common_test_Linux/lib/* ${TARGET_DIR}/usr/lib/
	cp -r $(@D)/examples/rknn_common_test/install/rknn_common_test_Linux/model/ ${TARGET_DIR}/usr/share/
endef

$(eval $(generic-package))
