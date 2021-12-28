################################################################################
#
# gst1-plugins-good
#
################################################################################

ifeq ($(BR2_PACKAGE_LINUX_RGA),y)
GST1_PLUGINS_GOOD_DEPENDENCIES += linux-rga
endif


ifeq ($(BR2_PACKAGE_GSTREAMER1_14),y)
include $(pkgdir)/1_14.inc
else ifeq ($(BR2_PACKAGE_GSTREAMER1_18),y)
include $(pkgdir)/1_18.inc
endif
