################################################################################
#
# LittleVGL
#
################################################################################

LVGL_VERSION = 8.3.0
LVGL_SITE = $(call github,lvgl,lvgl,v$(LVGL_VERSION))
LVGL_INSTALL_STAGING = YES

LVGL_DEPENDENCIES += freetype

ifeq ($(BR2_PACKAGE_LVGL_DEMOS), y)
LVGL_CONF_OPTS += -DLV_USE_DEMO_WIDGETS=1	\
	-DLV_USE_DEMO_KEYPAD_AND_ENCODER=1	\
	-DLV_USE_DEMO_BENCHMARK=1	\
	-DLV_USE_DEMO_STRESS=1	\
	-DLV_USE_DEMO_MUSIC=1
endif

ifeq ($(BR2_PACKAGE_LVGL_DEMO_CUSTOM), y)
LVGL_CONF_OPTS += -DLV_USE_DEMO_CUSTOM=1
endif

ifeq ($(BR2_PACKAGE_LVGL_USE_SDL), y)
LVGL_CONF_OPTS += -DLV_USE_GPU_SDL=1
LVGL_DEPENDENCIES += sdl2
endif

LVGL_CONF_OPTS += -DLV_COLOR_DEPTH=$(BR2_PACKAGE_LVGL_COLOR_DEPTH)
ifeq ($(BR2_PACKAGE_LVGL_COLOR_16_SWAP), y)
LVGL_CONF_OPTS += -DLV_COLOR_16_SWAP=1
else
LVGL_CONF_OPTS += -DLV_COLOR_16_SWAP=0
endif

$(eval $(cmake-package))
