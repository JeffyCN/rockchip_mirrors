################################################################################
#
# lv_drivers
#
################################################################################

LV_DRIVERS_VERSION = 8.3.0
LV_DRIVERS_SITE = $(call github,lvgl,lv_drivers,v$(LV_DRIVERS_VERSION))
LV_DRIVERS_INSTALL_STAGING = YES

LV_DRIVERS_DEPENDENCIES = lvgl

ifeq ($(BR2_PACKAGE_LV_DRIVERS_USE_SDL_GPU), y)
LV_DRIVERS_CONF_OPTS += -DLV_DRV_USE_SDL_GPU=1
LV_DRIVERS_DEPENDENCIES += sdl2
endif

ifeq ($(BR2_PACKAGE_LV_DRIVERS_USE_DRM), y)
LV_DRIVERS_CONF_OPTS += -DLV_DRV_USE_DRM=1
LV_DRIVERS_DEPENDENCIES += libdrm
endif

ifeq ($(BR2_PACKAGE_LV_DRIVERS_USE_RGA), y)
LV_DRIVERS_CONF_OPTS += -DLV_DRV_USE_RGA=1
LV_DRIVERS_DEPENDENCIES += rockchip-rga
endif

LV_DRIVERS_CONF_OPTS += -DLV_COLOR_DEPTH=$(BR2_PACKAGE_LVGL_COLOR_DEPTH)
ifeq ($(BR2_PACKAGE_LVGL_COLOR_16_SWAP), y)
LV_DRIVERS_CONF_OPTS += -DLV_COLOR_16_SWAP=1
else
LV_DRIVERS_CONF_OPTS += -DLV_COLOR_16_SWAP=0
endif

$(eval $(cmake-package))
