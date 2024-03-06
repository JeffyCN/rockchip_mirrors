################################################################################
#
# lvgl_demo
#
################################################################################

LVGL_DEMO_SITE = $(TOPDIR)/../app/lvgl_demo
LVGL_DEMO_SITE_METHOD = local

# add dependencies
LVGL_DEMO_DEPENDENCIES += lvgl

LVGL_DEMO_INSTALL_STAGING = YES

ifeq ($(BR2_PACKAGE_LVGL_DEMO_WIDGETS), y)
LVGL_DEMO_CONF_OPTS += -DLV_USE_DEMO_WIDGETS=1
endif

ifeq ($(BR2_PACKAGE_LVGL_DEMO_KEYPAD_AND_ENCODER), y)
LVGL_DEMO_CONF_OPTS += -DLV_USE_DEMO_KEYPAD_AND_ENCODER=1
endif

ifeq ($(BR2_PACKAGE_LVGL_DEMO_BENCHMARK), y)
LVGL_DEMO_CONF_OPTS += -DLV_USE_DEMO_BENCHMARK=1
endif

ifeq ($(BR2_PACKAGE_LVGL_DEMO_STRESS), y)
LVGL_DEMO_CONF_OPTS += -DLV_USE_DEMO_STRESS=1
endif

ifeq ($(BR2_PACKAGE_LVGL_DEMO_MUSIC), y)
LVGL_DEMO_CONF_OPTS += -DLV_USE_DEMO_MUSIC=1
endif

ifeq ($(BR2_PACKAGE_LVGL_DEMO_CUSTOM), y)
LVGL_DEMO_CONF_OPTS += -DLV_USE_DEMO_CUSTOM=1
endif

ifeq ($(BR2_PACKAGE_RK_DEMO), y)
LVGL_DEMO_DEPENDENCIES += rkadk rkwifibt-app
LVGL_DEMO_CONF_OPTS += -DLV_USE_RK_DEMO=1
endif

ifeq ($(BR2_PACKAGE_LVGL_USE_SDL), y)
LVGL_DEMO_CONF_OPTS += -DLV_DRV_USE_SDL_GPU=1
LV_DRIVERS_DEPENDENCIES += sdl2
endif

ifeq ($(BR2_PACKAGE_LVGL_USE_DRM), y)
LVGL_DEMO_CONF_OPTS += -DLV_DRV_USE_DRM=1
LV_DRIVERS_DEPENDENCIES += libdrm
endif

$(eval $(cmake-package))
