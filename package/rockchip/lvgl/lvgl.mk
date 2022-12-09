################################################################################
#
# lvgl
#
################################################################################

LVGL_VERSION = 8.2.0
LVGL_SITE_METHOD = local
LVGL_SITE = $(TOPDIR)/../external/lvgl
LVGL_INSTALL_STAGING = YES

LVGL_DEPENDENCIES += freetype
LVGL_APP_CFLAGS = -I $(STAGING_DIR)/usr/include/freetype2

define LVGL_PRE_RSYNC_INSTALL_CONFIG
        cp -rfp  $(LVGL_SITE)/rockchip-conf/$(BR2_PACKAGE_LVGL_CONF)  $(LVGL_SITE)/lv_conf.h | true
endef

LVGL_CONF_OPTS += -DCMAKE_C_FLAGS="$(LVGL_APP_CFLAGS)" \
                  -DCMAKE_CXX_FLAGS="$(LVGL_APP_CFLAGS)"

LVGL_PRE_RSYNC_HOOKS += LVGL_PRE_RSYNC_INSTALL_CONFIG

$(eval $(cmake-package))