################################################################################
#
# stress app test
#
################################################################################
STRESSAPPTEST_SITE = https://github.com/stressapptest/stressapptest.git
STRESS_LICENSE = Apache-2.0
STRESS_LICENSE_FILES = COPYING
STRESSAPPTEST_VERSION = master

$(eval $(autotools-package))
