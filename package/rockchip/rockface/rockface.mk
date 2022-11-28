ifeq ($(BR2_PACKAGE_ROCKFACE), y)
    ROCKFACE_SITE = $(TOPDIR)/../external/rockface
    ROCKFACE_SITE_METHOD = local
    ROCKFACE_INSTALL_STAGING = YES
    ROCKFACE_DEPENDENCIES = rknpu

ifeq ($(BR2_PACKAGE_RK1806),y)
    ROCKFACE_COMPILE_PLATFORM = rk1806
endif

ifeq ($(BR2_PACKAGE_RV1126_RV1109),y)
    ROCKFACE_COMPILE_PLATFORM = rv1109
endif

ifeq ($(BR2_PACKAGE_RK1808),y)
    ROCKFACE_COMPILE_PLATFORM = rk1808
endif

ifeq ($(BR2_PACKAGE_RK3399PRO),y)
    ROCKFACE_COMPILE_PLATFORM = rk3399pro
endif

ifeq ($(BR2_arm),y)
    ROCKFACE_COMPILE_LIB = lib
else
    ROCKFACE_COMPILE_LIB = lib64
endif

ROCKFACE_CONF_OPTS = -DCOMPILE_PLATFORM=$(ROCKFACE_COMPILE_PLATFORM)-Linux -DCOMPILE_LIB=$(ROCKFACE_COMPILE_LIB)

ifeq ($(BR2_PACKAGE_ROCKFACE_FACE_DETECTION),y)
    ROCKFACE_CONF_OPTS += -DWITH_FACE_DETECTION=1
endif

ifeq ($(BR2_PACKAGE_ROCKFACE_FACE_DETECTION_V2),y)
    ROCKFACE_CONF_OPTS += -DWITH_FACE_DETECTION_V2=1
endif

ifeq ($(BR2_PACKAGE_ROCKFACE_FACE_DETECTION_V3),y)
    ROCKFACE_CONF_OPTS += -DWITH_FACE_DETECTION_V3=1
endif

ifeq ($(BR2_PACKAGE_ROCKFACE_FACE_DETECTION_V3_FAST),y)
    ROCKFACE_CONF_OPTS += -DWITH_FACE_DETECTION_V3_FAST=1
endif

ifeq ($(BR2_PACKAGE_ROCKFACE_FACE_DETECTION_V3_LARGE),y)
    ROCKFACE_CONF_OPTS += -DWITH_FACE_DETECTION_V3_LARGE=1
endif

ifeq ($(BR2_PACKAGE_ROCKFACE_FACE_RECOGNITION),y)
    ROCKFACE_CONF_OPTS += -DWITH_FACE_RECOGNITION=1
endif

ifeq ($(BR2_PACKAGE_ROCKFACE_FACE_LANDMARK),y)
    ROCKFACE_CONF_OPTS += -DWITH_FACE_LANDMARK=1
endif

ifeq ($(BR2_PACKAGE_ROCKFACE_FACE_ATTRIBUTE),y)
    ROCKFACE_CONF_OPTS += -DWITH_FACE_ATTRIBUTE=1
endif

ifeq ($(BR2_PACKAGE_ROCKFACE_LIVING_DETECTION),y)
    ROCKFACE_CONF_OPTS += -DWITH_LIVING_DETECTION=1
endif

ifeq ($(BR2_PACKAGE_ROCKFACE_OBJECT_DETECTION),y)
    ROCKFACE_CONF_OPTS += -DWITH_OBJECT_DETECTION=1
endif

ifeq ($(BR2_PACKAGE_ROCKFACE_MASK_CLASSIFY),y)
    ROCKFACE_CONF_OPTS += -DWITH_MASK_CLASSIFY=1
endif

ifeq ($(BR2_PACKAGE_ROCKFACE_MASK_LANDMARKS),y)
    ROCKFACE_CONF_OPTS += -DWITH_MASK_LANDMARKS=1
endif

ifeq ($(BR2_PACKAGE_ROCKFACE_MASK_RECOGNITION),y)
    ROCKFACE_CONF_OPTS += -DWITH_MASK_RECOGNITION=1
endif

ifeq ($(BR2_PACKAGE_ROCKFACE_MASKS_DETECTION),y)
    ROCKFACE_CONF_OPTS += -DWITH_MASKS_DETECTION=1
endif

    $(eval $(cmake-package))
endif
