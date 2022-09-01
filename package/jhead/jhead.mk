################################################################################
#
# jhead
#
################################################################################

JHEAD_VERSION = 3.06.0.1
JHEAD_SITE = $(call github,Matthias-Wandel,jhead,$(JHEAD_VERSION))
JHEAD_LICENSE = Public Domain
JHEAD_LICENSE_FILES = readme.txt
JHEAD_CPE_ID_VENDOR = jhead_project
JHEAD_INSTALL_STAGING = YES

$(eval $(meson-package))
