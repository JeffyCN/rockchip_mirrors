################################################################################
#
# stress-ng
#
################################################################################

STRESS_NG_VERSION = 0.15.07
STRESS_NG_SITE = $(call github,ColinIanKing,stress-ng,V$(STRESS_NG_VERSION))
STRESS_NG_LICENSE = GPL-2.0+
STRESS_NG_LICENSE_FILES = COPYING

STRESS_NG_MAKE_FLAGS = \
	PRESERVE_CFLAGS=1
STRESS_NG_LDFLAGS = "$(TARGET_LDFLAGS)"

ifeq ($(BR2_PACKAGE_LIBBSD),y)
STRESS_NG_DEPENDENCIES += libbsd
endif

ifeq ($(BR2_PACKAGE_KEYUTILS),y)
STRESS_NG_DEPENDENCIES += keyutils
endif

ifeq ($(BR2_TOOLCHAIN_HAS_LIBATOMIC),y)
STRESS_NG_LDFLAGS += -latomic
endif

ifeq ($(BR2_PACKAGE_HAS_LIBGBM),y)
STRESS_NG_DEPENDENCIES += libgbm
STRESS_NG_LDFLAGS += `$(PKG_CONFIG_HOST_BINARY) --libs gbm`
endif

STRESS_NG_MAKE_FLAGS += LDFLAGS="$(STRESS_NG_LDFLAGS)"

define STRESS_NG_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) $(STRESS_NG_MAKE_FLAGS)
endef

# Don't use make install otherwise stress-ng will be rebuild without
# required link libraries if any. Furthermore, using INSTALL allow to
# set the file permission correcly on the target.
define STRESS_NG_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/stress-ng $(TARGET_DIR)/usr/bin/stress-ng
endef

$(eval $(generic-package))
