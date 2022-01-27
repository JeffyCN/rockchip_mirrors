################################################################################
#
# rockchip-mpp
#
################################################################################

ROCKCHIP_MPP_SITE = $(TOPDIR)/../external/mpp
ROCKCHIP_MPP_VERSION = release
ROCKCHIP_MPP_SITE_METHOD = local

ROCKCHIP_MPP_CONF_OPTS = "-DRKPLATFORM=ON"
ROCKCHIP_MPP_CONF_DEPENDENCIES += libdrm

ROCKCHIP_MPP_INSTALL_STAGING = YES

ifeq ($(BR2_PACKAGE_ROCKCHIP_MPP_ALLOCATOR_DRM),y)
ROCKCHIP_MPP_CONF_OPTS += "-DHAVE_DRM=ON"
endif

ifeq ($(BR2_PACKAGE_ROCKCHIP_MPP_TESTS),y)
ROCKCHIP_MPP_CONF_OPTS += "-DBUILD_TEST=ON"
endif

define ROCKCHIP_MPP_LINK_GIT
	rm -rf $(@D)/.git
	ln -s $(SRCDIR)/.git $(@D)/
endef

ROCKCHIP_MPP_POST_RSYNC_HOOKS += MPP_LINK_GIT

$(eval $(cmake-package))
