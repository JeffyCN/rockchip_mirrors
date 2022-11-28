################################################################################
#
# lvgl
#
################################################################################

LVGL_VERSION = 8.2.0
LVGL_SOURCE = v$(LVGL_VERSION).tar.gz
LVGL_SITE = https://github.com/lvgl/lvgl/archive/refs/tags
LVGL_INSTALL_STAGING = YES

$(eval $(cmake-package))
