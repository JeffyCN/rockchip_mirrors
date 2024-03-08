################################################################################
#
# input-event-daemon
#
################################################################################

INPUT_EVENT_DAEMON_VERSION = 0.1.3
INPUT_EVENT_DAEMON_SITE = $(call github,gandro,input-event-daemon,v$(INPUT_EVENT_DAEMON_VERSION))
INPUT_EVENT_DAEMON_LICENSE = input-event-daemon license
INPUT_EVENT_DAEMON_LICENSE_FILES = README

INPUT_EVENT_DAEMON_LDFLAGS = $(TARGET_LDFLAGS)

ifeq ($(BR2_PACKAGE_INPUT_EVENT_DAEMON_STATIC),y)
INPUT_EVENT_DAEMON_LDFLAGS += -static
endif

define INPUT_EVENT_DAEMON_BUILD_CMDS
	touch $(@D)/input-event-table.h
	$(TARGET_MAKE_ENV) $(MAKE) CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(INPUT_EVENT_DAEMON_LDFLAGS)" -C $(@D)
endef

define INPUT_EVENT_DAEMON_INSTALL_TARGET_CMDS
	$(INSTALL) -m 755 -D $(@D)/input-event-daemon \
		$(TARGET_DIR)/usr/bin/input-event-daemon
	$(INSTALL) -m 644 -D $(@D)/docs/sample.conf \
		$(TARGET_DIR)/etc/input-event-daemon.conf
	$(INSTALL) -m 0755 -d $(TARGET_DIR)/etc/input-event-daemon.conf.d/

	# Listen all devices by default.
	$(SED) '/^listen = /d' $(TARGET_DIR)/etc/input-event-daemon.conf
endef

ifeq ($(BR2_PACKAGE_INPUT_EVENT_DAEMON_POWER_KEY),y)
define INPUT_EVENT_DAEMON_INSTALL_TARGET_POWER_KEY
	$(INSTALL) -m 0755 -D $(INPUT_EVENT_DAEMON_PKGDIR)/power-key.sh \
		$(TARGET_DIR)/usr/bin/
	$(INSTALL) -m 0755 -D $(INPUT_EVENT_DAEMON_PKGDIR)/power-key.conf \
		$(TARGET_DIR)/etc/input-event-daemon.conf.d/
endef
INPUT_EVENT_DAEMON_POST_INSTALL_TARGET_HOOKS += \
	INPUT_EVENT_DAEMON_INSTALL_TARGET_POWER_KEY
endif

define INPUT_EVENT_DAEMON_INSTALL_INIT_SYSV
	$(INSTALL) -m 0755 -D package/input-event-daemon/S99input-event-daemon \
		$(TARGET_DIR)/etc/init.d/S99input-event-daemon
endef

define INPUT_EVENT_DAEMON_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 package/input-event-daemon/input-event-daemon.service \
		$(TARGET_DIR)/usr/lib/systemd/system/input-event-daemon.service
endef

$(eval $(generic-package))
