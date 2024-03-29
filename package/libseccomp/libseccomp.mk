################################################################################
#
# libseccomp
#
################################################################################

LIBSECCOMP_VERSION = 2.5.5
LIBSECCOMP_SITE = https://github.com/seccomp/libseccomp/releases/download/v$(LIBSECCOMP_VERSION)
LIBSECCOMP_LICENSE = LGPL-2.1
LIBSECCOMP_LICENSE_FILES = LICENSE
LIBSECCOMP_CPE_ID_VALID = YES
LIBSECCOMP_INSTALL_STAGING = YES
LIBSECCOMP_DEPENDENCIES = host-gperf

$(eval $(autotools-package))
