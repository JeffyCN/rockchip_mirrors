################################################################################
#
# rockchip-mali
#
################################################################################

ROCKCHIP_MALI_VERSION = master
ROCKCHIP_MALI_SITE = $(TOPDIR)/../external/libmali
ROCKCHIP_MALI_SITE_METHOD = local
ROCKCHIP_MALI_LICENSE = ARM
ROCKCHIP_MALI_LICENSE_FILES = END_USER_LICENCE_AGREEMENT.txt
ROCKCHIP_MALI_INSTALL_STAGING = YES

ifeq ($(BR2_PACKAGE_ROCKCHIP_MALI_HAS_EGL),y)
ROCKCHIP_MALI_PROVIDES += libegl
endif

ifeq ($(BR2_PACKAGE_ROCKCHIP_MALI_HAS_GBM),y)
ROCKCHIP_MALI_PROVIDES += libgbm
endif

ifeq ($(BR2_PACKAGE_ROCKCHIP_MALI_HAS_GLES),y)
ROCKCHIP_MALI_PROVIDES += libgles
endif

ifeq ($(BR2_PACKAGE_ROCKCHIP_MALI_HAS_OPENCL),y)
ROCKCHIP_MALI_PROVIDES += libopencl
endif

ROCKCHIP_MALI_DEPENDENCIES = libdrm

ifeq ($(BR2_PACKAGE_ROCKCHIP_MALI_HAS_X11),y)
ROCKCHIP_MALI_DEPENDENCIES += libxcb xlib_libX11
endif

ifeq ($(BR2_PACKAGE_ROCKCHIP_MALI_HAS_WAYLAND),y)
ROCKCHIP_MALI_DEPENDENCIES += wayland
endif

ifeq ($(BR2_PACKAGE_PX3SE),y)
ROCKCHIP_MALI_GPU = utgard-400
ROCKCHIP_MALI_VER = r7p0
ROCKCHIP_MALI_SUBVER = r3p0
else ifneq ($(BR2_PACKAGE_RK312X)$(BR2_PACKAGE_RK3128H)$(BR2_PACKAGE_RK3036)$(BR2_PACKAGE_RK3032),)
ROCKCHIP_MALI_GPU = utgard-400
ROCKCHIP_MALI_VER = r7p0
ROCKCHIP_MALI_SUBVER = r1p1
else ifeq ($(BR2_PACKAGE_RK3328),y)
ROCKCHIP_MALI_GPU = utgard-450
ROCKCHIP_MALI_VER = r7p0
else ifeq ($(BR2_PACKAGE_RK3288),y)
ROCKCHIP_MALI_GPU = midgard-t76x
ROCKCHIP_MALI_VER = r18p0
ROCKCHIP_MALI_SUBVER = all
else ifneq ($(BR2_PACKAGE_RK3399)$(BR2_PACKAGE_RK3399PRO),)
ROCKCHIP_MALI_GPU = midgard-t86x
ROCKCHIP_MALI_VER = r18p0
else ifneq ($(BR2_PACKAGE_RK3326)$(BR2_PACKAGE_PX30),)
ROCKCHIP_MALI_GPU = bifrost-g31
ROCKCHIP_MALI_VER = g2p0
else ifeq ($(BR2_PACKAGE_RK356X),y)
ROCKCHIP_MALI_GPU = bifrost-g52
ROCKCHIP_MALI_VER = g2p0
else ifeq ($(BR2_PACKAGE_RK3588),y)
ROCKCHIP_MALI_GPU = valhall-g610
ROCKCHIP_MALI_VER = g6p0
endif

ifneq ($(BR2_PACKAGE_ROCKCHIP_MALI_CUSTOM_PLATFORM),"")
ROCKCHIP_MALI_PLATFORM = $(BR2_PACKAGE_ROCKCHIP_MALI_CUSTOM_PLATFORM)
else

# OpenCL is enabled by default for DDK newer than utgard.
ifneq ($(findstring utgard,$(ROCKCHIP_MALI_PLATFORM)),)
ifeq ($(BR2_PACKAGE_ROCKCHIP_MALI_HAS_OPENCL),)
ROCKCHIP_MALI_PLATFORM += without-cl
endif
endif

ifeq ($(BR2_PACKAGE_ROCKCHIP_MALI_HAS_DUMMY),y)
ROCKCHIP_MALI_PLATFORM += dummy
endif

ifeq ($(BR2_PACKAGE_ROCKCHIP_MALI_HAS_X11),y)
ROCKCHIP_MALI_PLATFORM += x11
endif

ifeq ($(BR2_PACKAGE_ROCKCHIP_MALI_HAS_WAYLAND),y)
ROCKCHIP_MALI_PLATFORM += wayland
endif

ifeq ($(BR2_PACKAGE_ROCKCHIP_MALI_HAS_GBM),y)
ROCKCHIP_MALI_PLATFORM += gbm
endif

# Minimal library only for OpenCL.
ifeq ($(ROCKCHIP_MALI_PLATFORM)|$(BR2_PACKAGE_ROCKCHIP_MALI_HAS_OPENCL),|y)
ROCKCHIP_MALI_PLATFORM = only-cl
endif

endif

ROCKCHIP_MALI_CONF_OPTS += \
	-Dwith-overlay=true -Dopencl-icd=false -Dkhr-header=true \
	-Dgpu=$(ROCKCHIP_MALI_GPU) -Dversion=$(ROCKCHIP_MALI_VER) \
	-Dsubversion=$(subst $(eval) $(eval),-,$(ROCKCHIP_MALI_SUBVER)) \
	-Dplatform=$(subst $(eval) $(eval),-,$(ROCKCHIP_MALI_PLATFORM))

ifeq ($(BR2_PACKAGE_ROCKCHIP_MALI_OPTIMIZE_s),y)
ROCKCHIP_MALI_CONF_OPTS += -Doptimize-level=Os
endif

$(eval $(meson-package))
