################################################################################
#
# rkwifibt
#
################################################################################

RKWIFIBT_VERSION = 1.0.0
RKWIFIBT_SITE_METHOD = local
RKWIFIBT_SITE = $(TOPDIR)/../external/rkwifibt
RKWIFIBT_LICENSE = ROCKCHIP
RKWIFIBT_LICENSE_FILES = LICENSE

RKWIFIBT_DEPENDENCIES = wpa_supplicant

GCCVER = $(TOPDIR)/../prebuilts/gcc/linux-x86/arm/gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf
GCC10 = $(shell if [ -d $(GCCVER) ]; then echo "GCC10"; fi)
ifneq ($(findstring $(GCC10), "GCC10"),)
CROSS_COMPILE32=$(TOPDIR)/../prebuilts/gcc/linux-x86/arm/gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf/bin/arm-linux-gnueabihf-
CROSS_COMPILE64=$(TOPDIR)/../prebuilts/gcc/linux-x86/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
endif
$(info $(TOPDIR) $(GCCVER) $(GCC10) $(CROSS_COMPILE))

BT_TTY_DEV = $(call qstrip,$(BR2_PACKAGE_RKWIFIBT_BTUART))
SXLOAD_WIFI = "S36load_wifi_modules"
FIRMWARE_DIR = system

ifeq ($(call qstrip,$(BR2_ARCH)),aarch64)
RKWIFIBT_ARCH=arm64
CROSS_COMPILE=$(CROSS_COMPILE64)
else ifeq ($(call qstrip,$(BR2_ARCH)),arm)
CROSS_COMPILE=$(CROSS_COMPILE32)
RKWIFIBT_ARCH=arm
endif

BT_DRIVER_ARCH = $(shell grep -o "arm64" $(TOPDIR)/../kernel/.config)
$(info $(BT_DRIVER_ARCH))
ifneq ($(findstring arm64, $(BT_DRIVER_ARCH)),)
BT_DRIVER_ARCH = arm64
else
BT_DRIVER_ARCH = arm
endif
$(info $(BT_DRIVER_ARCH))

ifeq (y,$(BR2_PACKAGE_RKWIFIBT_ALL))
SXLOAD_WIFI = "S36load_all_wifi_modules"
endif

define RKWIFIBT_INSTALL_COMMON
	mkdir -p $(TARGET_DIR)/lib/firmware $(TARGET_DIR)/usr/lib/modules $(TARGET_DIR)/$(FIRMWARE_DIR)/etc/firmware $(TARGET_DIR)/lib/firmware/rtlbt
	$(INSTALL) -D -m 0755 $(@D)/wpa_supplicant.conf $(TARGET_DIR)/etc/
	$(INSTALL) -D -m 0755 $(@D)/dnsmasq.conf $(TARGET_DIR)/etc/
	$(INSTALL) -D -m 0755 $(@D)/wifi_start.sh $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 $(@D)/wifi_ap6xxx_rftest.sh $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 $(@D)/src/rk_wifi_init $(TARGET_DIR)/usr/bin/
	$(SED) 's/WIFI_KO/\/$(FIRMWARE_DIR)\/lib\/modules\/$(BR2_PACKAGE_RKWIFIBT_WIFI_KO)/g' $(@D)/$(SXLOAD_WIFI)
	$(SED) 's/BT_TTY_DEV/\/dev\/$(BT_TTY_DEV)/g' $(@D)/$(SXLOAD_WIFI)
	-$(INSTALL) -D -m 0755 $(@D)/$(SXLOAD_WIFI) $(TARGET_DIR)/etc/init.d/
endef

define RKWIFIBT_TB_INSTALL
	mkdir -p $(TARGET_DIR)/$(FIRMWARE_DIR)/etc/firmware
	$(INSTALL) -D -m 0755 $(@D)/wpa_supplicant.conf $(TARGET_DIR)/etc/
	$(INSTALL) -D -m 0644 $(@D)/firmware/broadcom/$(BR2_PACKAGE_RKWIFIBT_CHIPNAME)/wifi/* $(TARGET_DIR)/$(FIRMWARE_DIR)/etc/firmware/
	$(INSTALL) -D -m 0755 $(@D)/tb_start_wifi.sh $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 $(@D)/brcm_tools/dhd_priv $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 $(@D)/src/CY_WL_API/keepalive $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 $(@D)/bin/$(RKWIFIBT_ARCH)/* $(TARGET_DIR)/usr/bin/

	$(INSTALL) -D -m 0644 $(TOPDIR)/../kernel/drivers/net/wireless/rockchip_wlan/rkwifi/rk_wifi_config.ko $(TARGET_DIR)/$(FIRMWARE_DIR)/lib/modules/
	$(INSTALL) -D -m 0644 $(TOPDIR)/../kernel/net/rfkill/rfkill.ko $(TARGET_DIR)/$(FIRMWARE_DIR)/lib/modules/
	$(INSTALL) -D -m 0644 $(TOPDIR)/../kernel/net/rfkill/rfkill-rk.ko $(TARGET_DIR)/$(FIRMWARE_DIR)/lib/modules/
	$(INSTALL) -D -m 0644 $(TOPDIR)/../kernel/net/wireless/cfg80211.ko $(TARGET_DIR)/$(FIRMWARE_DIR)/lib/modules/
	$(INSTALL) -D -m 0644 $(TOPDIR)/../kernel/net/mac80211/mac80211.ko $(TARGET_DIR)/$(FIRMWARE_DIR)/lib/modules/
	-$(TARGET_STRIP) $(STRIP_STRIP_DEBUG) $(TARGET_DIR)/$(FIRMWARE_DIR)/lib/modules/*.ko
endef

define RKWIFIBT_BROADCOM_INSTALL
	$(INSTALL) -D -m 0644 $(@D)/firmware/broadcom/$(BR2_PACKAGE_RKWIFIBT_CHIPNAME)/wifi/* $(TARGET_DIR)/$(FIRMWARE_DIR)/etc/firmware/
	$(INSTALL) -D -m 0755 $(@D)/brcm_tools/brcm_patchram_plus1 $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 $(@D)/brcm_tools/dhd_priv $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 $(@D)/bin/$(RKWIFIBT_ARCH)/* $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0644 $(@D)/firmware/broadcom/$(BR2_PACKAGE_RKWIFIBT_CHIPNAME)/bt/* $(TARGET_DIR)/$(FIRMWARE_DIR)/etc/firmware/
	$(INSTALL) -D -m 0755 $(@D)/bt_load_broadcom_firmware $(TARGET_DIR)/usr/bin/
	$(SED) 's/BT_TTY_DEV/\/dev\/$(BT_TTY_DEV)/g' $(TARGET_DIR)/usr/bin/bt_load_broadcom_firmware
	$(INSTALL) -D -m 0755 $(TARGET_DIR)/usr/bin/bt_load_broadcom_firmware $(TARGET_DIR)/usr/bin/bt_pcba_test
	$(INSTALL) -D -m 0755 $(TARGET_DIR)/usr/bin/bt_load_broadcom_firmware $(TARGET_DIR)/usr/bin/bt_init.sh
endef

define RKWIFIBT_REALTEK_WIFI_INSTALL
	$(INSTALL) -D -m 0755 $(@D)/bin/$(RKWIFIBT_ARCH)/rtwpriv $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 $(@D)/$(SXLOAD_WIFI) $(TARGET_DIR)/etc/init.d/
endef

define RKWIFIBT_REALTEK_BT_INSTALL
	$(INSTALL) -D -m 0755 $(@D)/realtek/rtk_hciattach/rtk_hciattach $(TARGET_DIR)/usr/bin/rtk_hciattach
	$(INSTALL) -D -m 0755 $(@D)/bin/$(RKWIFIBT_ARCH)/* $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0644 $(@D)/realtek/$(BR2_PACKAGE_RKWIFIBT_CHIPNAME)/* $(TARGET_DIR)/lib/firmware/rtlbt/
	$(INSTALL) -D -m 0644 $(@D)/realtek/$(BR2_PACKAGE_RKWIFIBT_CHIPNAME)/* $(TARGET_DIR)/lib/firmware/
	$(INSTALL) -D -m 0755 $(@D)/bt_realtek* $(TARGET_DIR)/usr/bin/
	-$(INSTALL) -D -m 0644 $(@D)/realtek/bluetooth_uart_driver/hci_uart.ko $(TARGET_DIR)/usr/lib/modules/hci_uart.ko
	-$(INSTALL) -D -m 0644 $(@D)/realtek/bluetooth_usb_driver/hci_btusb.ko $(TARGET_DIR)/usr/lib/modules/hci_btusb.ko
	$(INSTALL) -D -m 0755 $(@D)/bt_load_rtk_firmware $(TARGET_DIR)/usr/bin/
	$(SED) 's/BT_TTY_DEV/\/dev\/$(BT_TTY_DEV)/g' $(TARGET_DIR)/usr/bin/bt_load_rtk_firmware
	$(INSTALL) -D -m 0755 $(TARGET_DIR)/usr/bin/bt_load_rtk_firmware $(TARGET_DIR)/usr/bin/bt_pcba_test
	$(INSTALL) -D -m 0755 $(TARGET_DIR)/usr/bin/bt_load_rtk_firmware $(TARGET_DIR)/usr/bin/bt_init.sh
endef

define RKWIFIBT_ROCKCHIP_INSTALL
	$(INSTALL) -D -m 0644 $(@D)/firmware/rockchip/WIFI_FIRMWARE/rk912* $(TARGET_DIR)/lib/firmware/
	$(INSTALL) -D -m 0755 $(@D)/S36load_wifi_rk912_modules $(TARGET_DIR)/etc/init.d/
endef

define RKWIFIBT_BUILD_CMDS
	ln -sf $(FIRMWARE_DIR) $(TARGET_DIR)/vendor
	mkdir -p $(TARGET_DIR)/$(FIRMWARE_DIR)/lib/modules/
	-$(TOPDIR)/../build.sh modules
	find $(TOPDIR)/../kernel/drivers/net/wireless/rockchip_wlan/* -name $(BR2_PACKAGE_RKWIFIBT_WIFI_KO) | xargs -n1 -i cp {} $(TARGET_DIR)/$(FIRMWARE_DIR)/lib/modules/
	-$(TARGET_STRIP) $(STRIP_STRIP_DEBUG) $(TARGET_DIR)/$(FIRMWARE_DIR)/lib/modules/*.ko
	$(TARGET_CC) -o $(@D)/brcm_tools/brcm_patchram_plus1 $(@D)/brcm_tools/brcm_patchram_plus1.c
	$(TARGET_CC) -o $(@D)/brcm_tools/dhd_priv $(@D)/brcm_tools/dhd_priv.c
	$(TARGET_CC) -o $(@D)/src/rk_wifi_init $(@D)/src/rk_wifi_init.c
	$(MAKE) -C $(@D)/realtek/rtk_hciattach/ CC=$(TARGET_CC)
	$(MAKE) -C $(@D)/src/CY_WL_API/ CC=$(TARGET_CC)
	-$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(TOPDIR)/../kernel/ M=$(@D)/realtek/bluetooth_uart_driver ARCH=$(BT_DRIVER_ARCH) CROSS_COMPILE=$(CROSS_COMPILE)
endef

ifneq ($(BR2_PACKAGE_THUNDERBOOT), y)

ifeq ($(BR2_PACKAGE_RKWIFIBT_VENDOR), "ALL")
define RKWIFIBT_INSTALL_TARGET_CMDS
	$(RKWIFIBT_INSTALL_COMMON)
	$(RKWIFIBT_BROADCOM_INSTALL)
	$(RKWIFIBT_REALTEK_WIFI_INSTALL)
	$(RKWIFIBT_REALTEK_BT_INSTALL)
endef
endif

ifeq ($(BR2_PACKAGE_RKWIFIBT_VENDOR), "BROADCOM")
define RKWIFIBT_INSTALL_TARGET_CMDS
	$(RKWIFIBT_INSTALL_COMMON)
	$(RKWIFIBT_BROADCOM_INSTALL)
endef
endif

ifeq ($(BR2_PACKAGE_RKWIFIBT_VENDOR), "CYPRESS")
define RKWIFIBT_INSTALL_TARGET_CMDS
	$(RKWIFIBT_INSTALL_COMMON)
	$(RKWIFIBT_BROADCOM_INSTALL)
endef
endif

else

define RKWIFIBT_INSTALL_TARGET_CMDS
	$(RKWIFIBT_TB_INSTALL)
endef

endif #THUNDERBOOT

ifeq ($(BR2_PACKAGE_RKWIFIBT_VENDOR), "REALTEK")

ifeq ($(BR2_PACKAGE_RKWIFIBT_BT_EN), "ENABLE")
define RKWIFIBT_INSTALL_TARGET_CMDS
	$(RKWIFIBT_INSTALL_COMMON)
	$(RKWIFIBT_REALTEK_WIFI_INSTALL)
	$(RKWIFIBT_REALTEK_BT_INSTALL)
endef
else
define RKWIFIBT_INSTALL_TARGET_CMDS
	$(RKWIFIBT_INSTALL_COMMON)
	$(RKWIFIBT_REALTEK_WIFI_INSTALL)
endef
endif

endif

ifeq ($(BR2_PACKAGE_RKWIFIBT_VENDOR), "ROCKCHIP")
define RKWIFIBT_INSTALL_TARGET_CMDS
	$(RKWIFIBT_INSTALL_COMMON)
	$(RKWIFIBT_ROCKCHIP_INSTALL)
endef
endif

define RKWIFIBT_POST_INSTALL_TARGET_HOOKS_CMDS
	-rm -f $(@D)/$(SXLOAD_WIFI)
endef

RKWIFIBT_POST_INSTALL_TARGET_HOOKS += RKWIFIBT_POST_INSTALL_TARGET_HOOKS_CMDS

$(eval $(generic-package))
