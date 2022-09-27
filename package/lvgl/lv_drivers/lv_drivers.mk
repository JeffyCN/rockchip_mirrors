################################################################################
#
# lv_drivers
#
################################################################################

LV_DRIVERS_VERSION = 8.3.0
LV_DRIVERS_SITE = $(call github,lvgl,lv_drivers,v$(LV_DRIVERS_VERSION))
LV_DRIVERS_INSTALL_STAGING = YES

LV_DRIVERS_DEPENDENCIES = lvgl libdrm

$(eval $(cmake-package))
