RKFSMK_SITE = $(TOPDIR)/../external/rkfsmk
RKFSMK_SITE_METHOD = local

RKFSMK_INSTALL_STAGING = YES

$(eval $(cmake-package))
