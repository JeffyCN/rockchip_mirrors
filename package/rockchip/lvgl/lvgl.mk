################################################################################
#
# lvgl
#
################################################################################

LVGL_VERSION = 8.2.0
LVGL_SITE_METHOD = local
LVGL_SITE = $(TOPDIR)/../external/lvgl
LVGL_INSTALL_STAGING = YES

$(eval $(cmake-package))
