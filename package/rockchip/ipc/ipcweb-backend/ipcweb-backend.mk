# Rockchip's MPP(Multimedia Processing Platform)
IPCWEB_BACKEND_SITE = $(TOPDIR)/../app/ipcweb-backend
IPCWEB_BACKEND_VERSION = release
IPCWEB_BACKEND_SITE_METHOD = local
IPCWEB_BACKEND_LICENSE = ROCKCHIP
IPCWEB_BACKEND_LICENSE_FILES = LICENSE

IPCWEB_BACKEND_DEPENDENCIES = libcgicc openssl minilogger json-for-modern-cpp fcgiwrap
IPCWEB_BACKEND_CONF_OPTS += -DIPCWEBBACKEND_BUILD_TESTS=OFF

ifeq ($(BR2_PACKAGE_IPCWEB_BACKEND_JWT), y)
IPCWEB_BACKEND_CONF_OPTS += -DENABLE_JWT=ON
else
IPCWEB_BACKEND_CONF_OPTS += -DENABLE_JWT=OFF
endif

ifeq ($(BR2_PACKAGE_MEDIASERVE_USE_ROCKFACE), y)
IPCWEB_BACKEND_CONF_OPTS += -DMEDIASERVER_ROCKFACE=ON
else
IPCWEB_BACKEND_CONF_OPTS += -DMEDIASERVER_ROCKFACE=OFF
endif

ifeq ($(BR2_PACKAGE_IPCWEB_BACKEND_USE_RKIPC), y)
IPCWEB_BACKEND_CONF_OPTS += -DUSE_RKIPC=ON
else
IPCWEB_BACKEND_CONF_OPTS += -DUSE_RKIPC=OFF
IPCWEB_BACKEND_DEPENDENCIES += libIPCProtocol
endif

ifeq ($(BR2_PACKAGE_RK_OEM), y)
IPCWEB_BACKEND_INSTALL_TARGET_OPTS = DESTDIR=$(BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR) install/fast
IPCWEB_BACKEND_DEPENDENCIES += rk_oem
IPCWEB_BACKEND_CONF_OPTS += -DIPCWEBBACKEND_INSTALL_ON_OEM_PARTITION=ON
IPCWEB_BACKEND_TARGET_INSTALL_DIR = $(BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR)
define IPCWEB_BACKEND_INSTALL_TARGET_CMDS
	rm -rf $(IPCWEB_BACKEND_TARGET_INSTALL_DIR)/www
	cp -rfp $(@D)/www $(IPCWEB_BACKEND_TARGET_INSTALL_DIR)/
	mkdir -p $(IPCWEB_BACKEND_TARGET_INSTALL_DIR)/www/cgi-bin/
	cp -rfp $(@D)/src/entry.cgi $(IPCWEB_BACKEND_TARGET_INSTALL_DIR)/www/cgi-bin/
	cp -rfp $(@D)/ipcweb-env-arm64/etc/init.d/S50fcgiwrap $(TARGET_DIR)/etc/init.d/
	cp -rfp $(@D)/ipcweb-env-arm64/etc/nginx/nginx.conf $(TARGET_DIR)/etc/nginx/nginx.conf
endef
else
define IPCWEB_BACKEND_INSTALL_TARGET_CMDS
	rm -rf $(TARGET_DIR)/usr/www
	cp -rfp $(@D)/www $(TARGET_DIR)/usr
	mkdir -p  $(TARGET_DIR)/usr/www/cgi-bin/
	cp -rfp $(@D)/src/entry.cgi $(TARGET_DIR)/usr/www/cgi-bin/
	cp -rfp $(@D)/ipcweb-env-arm64/etc/init.d/S50fcgiwrap $(TARGET_DIR)/etc/init.d/
	cp -rfp $(@D)/ipcweb-env-arm64/etc/nginx/nginx.conf $(TARGET_DIR)/etc/nginx/nginx.conf
endef
endif

$(eval $(cmake-package))
