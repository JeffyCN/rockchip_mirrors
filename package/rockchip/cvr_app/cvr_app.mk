CVR_APP_SITE = $(TOPDIR)/../app/cvr_app
CVR_APP_SITE_METHOD = local

# add dependencies
CVR_APP_DEPENDENCIES = rkfsmk camera-engine-rkaiq rkadk rockchip-rga lvgl

CVR_APP_INSTALL_STAGING = YES

$(eval $(cmake-package))
