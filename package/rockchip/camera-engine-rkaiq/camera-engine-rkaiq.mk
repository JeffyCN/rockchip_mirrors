################################################################################
#
# Rockchip Camera Engine RKaiq For Linux
#
################################################################################

CAMERA_ENGINE_RKAIQ_VERSION = 1.0
CAMERA_ENGINE_RKAIQ_SITE = $(TOPDIR)/../external/camera_engine_rkaiq
CAMERA_ENGINE_RKAIQ_SITE_METHOD = local
CAMERA_ENGINE_RKAIQ_INSTALL_STAGING = YES

CAMERA_ENGINE_RKAIQ_DISALLOW_CLANG = YES

CAMERA_ENGINE_RKAIQ_LICENSE = Apache-2.0
CAMERA_ENGINE_RKAIQ_LICENSE_FILES = NOTICE

CAMERA_ENGINE_RKAIQ_DEPENDENCIES =

CAMERA_ENGINE_RKAIQ_CONF_OPTS = -DBUILDROOT_BUILD_PROJECT=TRUE -DARCH=$(BR2_ARCH)

ifeq ($(BR2_PACKAGE_RV1126_RV1109), y)
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DISP_HW_VERSION=-DISP_HW_V20
CAMERA_ENGINE_RKAIQ_IQFILE_FORMAT=xml
else ifeq ($(BR2_PACKAGE_RK3566_RK3568), y)
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DISP_HW_VERSION=-DISP_HW_V21
CAMERA_ENGINE_RKAIQ_IQFILE_FORMAT=json
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DCMAKE_BUILD_TYPE=MinSizeRel
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DRKAIQ_TARGET_SOC=rk356x
else ifeq ($(BR2_PACKAGE_RK3588), y)
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DISP_HW_VERSION=-DISP_HW_V30
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DCMAKE_BUILD_TYPE=MinSizeRel
CAMERA_ENGINE_RKAIQ_IQFILE_FORMAT=json
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DRKAIQ_TARGET_SOC=rk3588
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DRKAIQ_ENABLE_CAMGROUP=TRUE
else ifeq ($(BR2_PACKAGE_RK3562), y)
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DISP_HW_VERSION=-DISP_HW_V32_LITE
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DCMAKE_BUILD_TYPE=MinSizeRel
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DRKAIQ_TARGET_SOC=rk3562
CAMERA_ENGINE_RKAIQ_IQFILE_FORMAT=json
else ifeq ($(BR2_PACKAGE_RK3576), y)
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DISP_HW_VERSION=-DISP_HW_V39
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DCMAKE_BUILD_TYPE=MinSizeRel
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DRKAIQ_TARGET_SOC=rk3576
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DRKAIQ_ENABLE_CAMGROUP=TRUE
endif

ifeq ($(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_RKISP_DEMO), y)
CAMERA_ENGINE_RKAIQ_DEPENDENCIES += rockchip-rga
endif

ifeq ($(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE_USE_BIN), y)

RKISP_PARSER_HOST_BINARY = $(HOST_DIR)/bin/rkisp_parser

define conver_iqfiles
dir=`echo $(1)`; \
iqfile=`echo $(2)`; \
if [[ -z "$$iqfile" ]]; then \
	echo "## conver iqfiles"; \
		for i in $$dir/*.$(CAMERA_ENGINE_RKAIQ_IQFILE_FORMAT); do \
			echo "### conver iqfiles: $$i"; \
			$(RKISP_PARSER_HOST_BINARY) $$i; \
		done; \
else  \
	echo "### conver iqfile: $$dir/$$iqfile"; \
	$(RKISP_PARSER_HOST_BINARY) $$dir/$$iqfile; \
fi;
endef

define INSTALL_RKISP_PARSER_M32_CMD
	$(INSTALL) -D -m  755 $(@D)/rkisp_parser_demo/bin/rkisp_parser_m32   $(HOST_DIR)/bin/rkisp_parser
endef

define INSTALL_RKISP_PARSER_M64_CMD
	$(INSTALL) -D -m  755 $(@D)/rkisp_parser_demo/bin/rkisp_parser_m64   $(HOST_DIR)/bin/rkisp_parser
endef

define IQFILE_CONVER_CMD
	$(foreach iqfile, $(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE)),
		$(call conver_iqfiles, $(@D)/iqfiles, $(iqfile))
	)
endef

define IQFILES_CONVER_CMD
	$(call conver_iqfiles, $(@D)/iqfiles)
endef

ifeq ($(BR2_arm), y)
CAMERA_ENGINE_RKAIQ_PRE_BUILD_HOOKS += INSTALL_RKISP_PARSER_M32_CMD
else
CAMERA_ENGINE_RKAIQ_PRE_BUILD_HOOKS += INSTALL_RKISP_PARSER_M64_CMD
endif

ifneq ($(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE)),)
CAMERA_ENGINE_RKAIQ_PRE_BUILD_HOOKS += IQFILE_CONVER_CMD
else
CAMERA_ENGINE_RKAIQ_PRE_BUILD_HOOKS += IQFILES_CONVER_CMD
endif
ifneq ($(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE)),)
CAMERA_ENGINE_RKAIQ_IQFILE = $(patsubst %.xml,%.bin,$(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE)))
else
CAMERA_ENGINE_RKAIQ_IQFILE = *.bin
endif
else # BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE_USE_BIN
ifneq ($(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE)),)
CAMERA_ENGINE_RKAIQ_IQFILE = $(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE))
else
ifeq ($(BR2_PACKAGE_RV1126_RV1109), y)
CAMERA_ENGINE_RKAIQ_IQFILE = isp20/*.xml
else ifeq ($(BR2_PACKAGE_RK3566_RK3568), y)
CAMERA_ENGINE_RKAIQ_IQFILE = isp21/*.json
else ifeq ($(BR2_PACKAGE_RK3562), y)
CAMERA_ENGINE_RKAIQ_IQFILE = isp32_lite/*.json
else ifeq ($(BR2_PACKAGE_RK3576), y)
CAMERA_ENGINE_RKAIQ_IQFILE = isp39/*.json
else ifeq ($(BR2_PACKAGE_RK3588), y)
CAMERA_ENGINE_RKAIQ_IQFILE = isp3x/*.json
endif
endif
endif # BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE_USE_BIN

ifeq ($(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_RKISP_DEMO), y)
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DENABLE_RKISP_DEMO=ON
endif

define CAMERA_ENGINE_RKAIQ_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) DESTDIR=$(STAGING_DIR) $(MAKE) -C $($(PKG)_BUILDDIR) install
endef

define CAMERA_ENGINE_RKAIQ_INSTALL_CMDS
	mkdir -p $(TARGET_DIR)/etc/iqfiles/
	mkdir -p $(TARGET_DIR)/usr/lib/
	mkdir -p $(TARGET_DIR)/usr/bin/
	$(TARGET_MAKE_ENV) DESTDIR=$(TARGET_DIR) $(MAKE) -C $($(PKG)_BUILDDIR) install
	$(INSTALL) -D -m  644 $(@D)/rkaiq/all_lib/MinSizeRel/librkaiq.so $(TARGET_DIR)/usr/lib/
	$(foreach iqfile,$(CAMERA_ENGINE_RKAIQ_IQFILE),
		$(INSTALL) -D -m  644 $(@D)/rkaiq/iqfiles/$(iqfile) \
		$(TARGET_DIR)/etc/iqfiles/
	)
endef

CAMERA_ENGINE_RKAIQ_POST_INSTALL_TARGET_HOOKS += CAMERA_ENGINE_RKAIQ_INSTALL_CMDS

ifeq ($(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE)),$(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_FAKE_CAMERA_IQFILE)))
ifeq ($(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE_USE_BIN), y)
define INSTALL_FAKE_CAMERA_IQFILE_CMD
	ln -sf `echo ${BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE} | sed "s/xml/bin/g"` \
		$(TARGET_DIR)/etc/iqfiles/FakeCamera.bin
endef
else
define INSTALL_FAKE_CAMERA_IQFILE_CMD
	ln -sf $(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE) \
		$(TARGET_DIR)/etc/iqfiles/FakeCamera.xml
endef
endif
else
define INSTALL_FAKE_CAMERA_IQFILE_CMD
	$(INSTALL) -D -m  644 $(@D)/iqfiles/$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_FAKE_CAMERA_IQFILE) \
		$(TARGET_DIR)/etc/iqfiles/FakeCamera.json
endef
endif

ifneq ($(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_FAKE_CAMERA_IQFILE)),)
CAMERA_ENGINE_RKAIQ_POST_INSTALL_TARGET_HOOKS += INSTALL_FAKE_CAMERA_IQFILE_CMD
endif

ifeq ($(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_INSTALL_AIISP), y)
ifeq ($(BR2_arm), y)
CAMERA_ENGINE_RKAIQ_PRE_BUILD_HOOKS += INSTALL_AIISP_FILES_M32_CMD
else
CAMERA_ENGINE_RKAIQ_PRE_BUILD_HOOKS += INSTALL_AIISP_FILES_M64_CMD
endif
endif

define INSTALL_AIISP_FILES_M32_CMD
	$(INSTALL) -D -m  644 $(@D)/rkaiq/algos/aiisp/aiisp_relate/imx415/libRkAIISP_32bit.so $(TARGET_DIR)/usr/lib/libRkAIISP.so
	$(INSTALL) -D -m  644 $(@D)/rkaiq/algos/aiisp/aiisp_relate/*.aiisp $(TARGET_DIR)/etc/iqfiles/
	$(INSTALL) -D -m  644 $(@D)/rkaiq/algos/aiisp/aiisp_relate/*.csv $(TARGET_DIR)/etc/iqfiles/
	$(INSTALL) -D -m  644 $(@D)/rkaiq/algos/aiisp/aiisp_relate/*.txt $(TARGET_DIR)/etc/iqfiles/
endef

define INSTALL_AIISP_FILES_M64_CMD
	$(INSTALL) -D -m  644 $(@D)/rkaiq/algos/aiisp/aiisp_relate/imx415/libRkAIISP_64bit.so $(TARGET_DIR)/usr/lib/libRkAIISP.so
	$(INSTALL) -D -m  644 $(@D)/rkaiq/algos/aiisp/aiisp_relate/*.aiisp $(TARGET_DIR)/etc/iqfiles/
	$(INSTALL) -D -m  644 $(@D)/rkaiq/algos/aiisp/aiisp_relate/*.csv $(TARGET_DIR)/etc/iqfiles/
	$(INSTALL) -D -m  644 $(@D)/rkaiq/algos/aiisp/aiisp_relate/*.txt $(TARGET_DIR)/etc/iqfiles/
endef

$(eval $(cmake-package))
$(eval $(host-generic-package))
