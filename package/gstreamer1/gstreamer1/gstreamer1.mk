################################################################################
#
# gstreamer1
#
################################################################################

define GSTREAMER1_INSTALL_TARGET_ENV
	$(INSTALL) -D -m 0644 $(GSTREAMER1_PKGDIR)/gst.sh \
		$(TARGET_DIR)/etc/profile.d/gst.sh
endef

GSTREAMER1_POST_INSTALL_TARGET_HOOKS += GSTREAMER1_INSTALL_TARGET_ENV

ifeq ($(BR2_PACKAGE_GSTREAMER1_14),y)
include $(pkgdir)/1_14.inc
else ifeq ($(BR2_PACKAGE_GSTREAMER1_18),y)
include $(pkgdir)/1_18.inc
endif
