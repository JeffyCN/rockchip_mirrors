ROCKX_SITE = $(TOPDIR)/../external/rockx
ROCKX_SITE_METHOD = local

ROCKX_INSTALL_STAGING = YES

ifeq ($(BR2_PACKAGE_RK1806),y)
ROCKX_COMPILE_PLATFORM = rk1806
endif

ifeq ($(BR2_PACKAGE_RK1808),y)
ROCKX_COMPILE_PLATFORM = rk1808
endif

ifeq ($(BR2_PACKAGE_RK3399PRO),y)
ROCKX_COMPILE_PLATFORM = rk3399pro
endif

ifeq ($(BR2_PACKAGE_RV1126_RV1109),y)
ROCKX_COMPILE_PLATFORM = rv1109

ifeq ($(BR2_PACKAGE_ROCKX_CARPLATE_RELATIVE),y)
ROCKX_CONF_OPTS += -DWITH_ROCKX_CARPLATE_RELATIVE=1
endif

ifeq ($(BR2_PACKAGE_ROCKX_FACE_DETECTION),y)
ROCKX_CONF_OPTS += -DWITH_ROCKX_FACE_DETECTION=1
endif

ifeq ($(BR2_PACKAGE_ROCKX_FACE_RECOGNITION),y)
ROCKX_CONF_OPTS += -DWITH_ROCKX_FACE_RECOGNITION=1
endif

ifeq ($(BR2_PACKAGE_ROCKX_FACE_LANDMARK),y)
ROCKX_CONF_OPTS += -DWITH_ROCKX_FACE_LANDMARK=1
endif

ifeq ($(BR2_PACKAGE_ROCKX_FACE_ATTRIBUTE),y)
ROCKX_CONF_OPTS += -DWITH_ROCKX_FACE_ATTRIBUTE=1
endif

ifeq ($(BR2_PACKAGE_ROCKX_HEAD_DETECTION),y)
ROCKX_CONF_OPTS += -DWITH_ROCKX_HEAD_DETECTION=1
endif

ifeq ($(BR2_PACKAGE_ROCKX_OBJECT_DETECTION),y)
ROCKX_CONF_OPTS += -DWITH_ROCKX_OBJECT_DETECTION=1
endif

ifeq ($(BR2_PACKAGE_ROCKX_POSE_BODY),y)
ROCKX_CONF_OPTS += -DWITH_ROCKX_POSE_BODY=1
endif

ifeq ($(BR2_PACKAGE_ROCKX_POSE_FINGER),y)
ROCKX_CONF_OPTS += -DWITH_ROCKX_POSE_FINGER=1
endif

ifeq ($(BR2_PACKAGE_ROCKX_POSE_HAND),y)
ROCKX_CONF_OPTS += -DWITH_ROCKX_POSE_HAND=1
endif

ifeq ($(BR2_PACKAGE_ROCKX_TB), y)
ROCKX_CONF_OPTS += -DENABLE_ROCKX_TB=ON
endif

ifeq ($(BR2_PACKAGE_ROCKX_PERSON_DETECTION), y)
ROCKX_CONF_OPTS += -DWITH_ROCKX_PERSON_DETECTION=1
endif

endif
ROCKX_CONF_OPTS += -DCOMPILE_PLATFORM=$(ROCKX_COMPILE_PLATFORM)-Linux

$(eval $(cmake-package))
