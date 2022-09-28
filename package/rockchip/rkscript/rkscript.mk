################################################################################
#
# rkscript
#
################################################################################

RKSCRIPT_SITE = $(TOPDIR)/../external/rkscript
RKSCRIPT_SITE_METHOD = local
RKSCRIPT_LICENSE = Apache V2.0
RKSCRIPT_LICENSE_FILES = NOTICE

RKSCRIPT_USB_CONFIG=$(BR2_PACKAGE_RKSCRIPT_EXTRA_USB_CONFIG)

ifeq ($(BR2_PACKAGE_RKSCRIPT_ADBD),y)
RKSCRIPT_USB_CONFIG += usb_adb_en
endif

ifeq ($(BR2_PACKAGE_RKSCRIPT_MTP),y)
RKSCRIPT_USB_CONFIG += usb_mtp_en
endif

ifeq ($(BR2_PACKAGE_RKSCRIPT_ACM),y)
RKSCRIPT_USB_CONFIG += usb_acm_en
endif

ifeq ($(BR2_PACKAGE_RKSCRIPT_NTB),y)
RKSCRIPT_USB_CONFIG += usb_ntb_en
endif

ifeq ($(BR2_PACKAGE_RKSCRIPT_UMS),y)
RKSCRIPT_USB_CONFIG += usb_ums_en \
	ums_block=$(BR2_PACKAGE_RKSCRIPT_UMS_PATH) \
	ums_block_size=$(BR2_PACKAGE_RKSCRIPT_UMS_SIZE) \
	ums_block_type=$(BR2_PACKAGE_RKSCRIPT_UMS_FSTYPE)

ifeq ($(BR2_PACKAGE_RKSCRIPT_UMS_RO),y)
RKSCRIPT_USB_CONFIG += ums_block_ro=on
endif

ifeq ($(BR2_PACKAGE_RKSCRIPT_UMS_AUTO_MOUNT),y)
RKSCRIPT_USB_CONFIG += ums_block_auto_mount=on
endif
endif

ifneq ($(BR2_PACKAGE_RKSCRIPT_DEFAULT_PCM),"")
define RKSCRIPT_INSTALL_TARGET_PCM_HOOK
	$(SED) "s#\#PCM_ID#$(BR2_PACKAGE_RKSCRIPT_DEFAULT_PCM)#g" \
		$(@D)/asound.conf.in
	$(INSTALL) -m 0644 -D $(@D)/asound.conf.in $(TARGET_DIR)/etc/asound.conf
endef
RKSCRIPT_POST_INSTALL_TARGET_HOOKS += RKSCRIPT_INSTALL_TARGET_PCM_HOOK
endif

ifeq ($(BR2_PACKAGE_HAS_UDEV),y)
define RKSCRIPT_INSTALL_TARGET_UDEV_RULES
	$(INSTALL) -m 0644 -D $(@D)/*.rules $(TARGET_DIR)/lib/udev/rules.d/
endef
RKSCRIPT_POST_INSTALL_TARGET_HOOKS += RKSCRIPT_INSTALL_TARGET_UDEV_RULES
endif

ifneq ($(BR2_PACKAGE_RK356X)$(BR2_PACKAGE_RV1126_RV1109)$(BR2_PACKAGE_RK3308),)
define RKSCRIPT_INSTALL_INIT_SYSV_IODOMAIN
	$(INSTALL) -m 0755 -D $(@D)/list-iodomain.sh $(TARGET_DIR)/usr/bin/
	$(INSTALL) -m 0755 -D $(@D)/S98iodomain.sh $(TARGET_DIR)/etc/init.d/
endef
endif

# The recovery will handle storages itself
ifneq ($(BR2_PACKAGE_RECOVERY)|$(BR2_PACKAGE_RECOVERY_USE_UPDATEENGINE),y|)
define RKSCRIPT_INSTALL_INIT_SYSV_MOUNTALL
	$(INSTALL) -m 0755 -D $(@D)/S21mountall.sh $(TARGET_DIR)/etc/init.d/
endef
endif

ifeq ($(BR2_PACKAGE_RKSCRIPT_BOOTANIM),y)
define RKSCRIPT_INSTALL_INIT_SYSV_BOOTANIM
	$(INSTALL) -m 0755 -D $(@D)/S31bootanim.sh $(TARGET_DIR)/etc/init.d/
endef
endif

define RKSCRIPT_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -d $(TARGET_DIR)/etc/init.d/
	$(INSTALL) -m 0755 -D $(@D)/usbdevice $(TARGET_DIR)/usr/bin/
	$(INSTALL) -m 0755 -D $(@D)/S50usbdevice $(TARGET_DIR)/etc/init.d/

	echo $(RKSCRIPT_USB_CONFIG) | xargs -n 1 > \
		$(TARGET_DIR)/etc/init.d/.usb_config

	$(INSTALL) -m 0755 -d $(TARGET_DIR)/etc/bootanim.d/
	$(INSTALL) -m 0755 -D $(@D)/bootanim $(TARGET_DIR)/usr/bin/
	$(INSTALL) -m 0755 -D $(RKSCRIPT_PKGDIR)/gst-bootanim.sh \
		$(TARGET_DIR)/etc/bootanim.d/
endef

define RKSCRIPT_INSTALL_INIT_SYSV
	$(RKSCRIPT_INSTALL_INIT_SYSV_MOUNTALL)
	$(RKSCRIPT_INSTALL_INIT_SYSV_IODOMAIN)
	$(RKSCRIPT_INSTALL_INIT_SYSV_BOOTANIM)
endef

define RKSCRIPT_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(@D)/usbdevice.service \
		$(TARGET_DIR)/usr/lib/systemd/system/
endef

$(eval $(generic-package))
