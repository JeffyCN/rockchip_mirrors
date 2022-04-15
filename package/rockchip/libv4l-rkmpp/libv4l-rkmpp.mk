################################################################################
#
# libv4l-rkmpp
#
################################################################################

LIBV4L_RKMPP_SITE = https://github.com/JeffyCN/libv4l-rkmpp.git
LIBV4L_RKMPP_VERSION = 8562eb7cddeebc4527ffe42139a89736f1c8c08a
LIBV4L_RKMPP_SITE_METHOD = git
LIBV4L_RKMPP_AUTORECONF = YES

LIBV4L_RKMPP_LICENSE = LGPL-2.1
LIBV4L_RKMPP_LICENSE_FILES = COPYING

LIBV4L_RKMPP_DEPENDENCIES = libv4l rockchip-mpp

$(eval $(autotools-package))
