LIBGDBUS_SITE = $(TOPDIR)/../app/libgdbus
LIBGDBUS_SITE_METHOD = local

LIBGDBUS_INSTALL_STAGING = YES

LIBGDBUS_DEPENDENCIES = libglib2 dbus

$(eval $(cmake-package))
