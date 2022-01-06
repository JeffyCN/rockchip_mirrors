################################################################################
#
# weston
#
################################################################################

ifeq ($(BR2_PACKAGE_LINUX_RGA),y)
WESTON_DEPENDENCIES += linux-rga
endif

ifeq ($(BR2_PACKAGE_HAS_LIBEGL_WAYLAND)$(BR2_PACKAGE_HAS_LIBGLES),yy)
WESTON_CONF_OPTS += -Dsimple-clients=all
else
WESTON_CONF_OPTS += -Dsimple-clients=
endif

ifeq ($(BR2_PACKAGE_WESTON_DEFAULT_PIXMAN),y)
define WESTON_INSTALL_PIXMAN_INI
        $(INSTALL) -D -m 0644 $(WESTON_PKGDIR)/pixman.ini \
                $(TARGET_DIR)/etc/xdg/weston/weston.ini.d/01-pixman.ini
endef

WESTON_POST_INSTALL_TARGET_HOOKS += WESTON_INSTALL_PIXMAN_INI
endif

define WESTON_INSTALL_TARGET_ENV
        $(INSTALL) -D -m 0644 $(WESTON_PKGDIR)/weston.sh \
                $(TARGET_DIR)/etc/profile.d/weston.sh
endef

WESTON_POST_INSTALL_TARGET_HOOKS += WESTON_INSTALL_TARGET_ENV

define WESTON_INSTALL_TARGET_SCRIPTS
        $(INSTALL) -D -m 0755 $(WESTON_PKGDIR)/weston-calibration-helper.sh \
                $(TARGET_DIR)/bin/weston-calibration-helper.sh
endef

WESTON_POST_INSTALL_TARGET_HOOKS += WESTON_INSTALL_TARGET_SCRIPTS

ifeq ($(BR2_PACKAGE_WESTON_8),y)
include $(pkgdir)/weston-8.inc
else
include $(pkgdir)/weston-9.inc
endif
