LIBRKDB_SITE = $(TOPDIR)/../app/librkdb
LIBRKDB_SITE_METHOD = local

LIBRKDB_INSTALL_STAGING = YES

LIBRKDB_DEPENDENCIES += libglib2 sqlite json-c

$(eval $(cmake-package))
