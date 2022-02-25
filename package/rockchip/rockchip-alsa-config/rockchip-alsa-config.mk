################################################################################
#
# rockchip-alsa-config
#
################################################################################

ROCKCHIP_ALSA_CONFIG_VERSION = 1.0
ROCKCHIP_ALSA_CONFIG_SITE = $(TOPDIR)/../external/alsa-config
ROCKCHIP_ALSA_CONFIG_SITE_METHOD = local

ROCKCHIP_ALSA_CONFIG_LICENSE = ROCKCHIP
ROCKCHIP_ALSA_CONFIG_LICENSE_FILES = LICENSE

$(eval $(meson-package))
