################################################################################
#
# python3-setuptools
#
################################################################################

# Please keep in sync with
# package/python-setuptools/python-setuptools.mk
PYTHON3_SETUPTOOLS_VERSION = 62.1.0
PYTHON3_SETUPTOOLS_SOURCE = setuptools-$(PYTHON_SETUPTOOLS_VERSION).tar.gz
PYTHON3_SETUPTOOLS_SITE = https://files.pythonhosted.org/packages/ea/a3/3d3cbbb7150f90c4cf554048e1dceb7c6ab330e4b9138a40e130a4cc79e1
PYTHON3_SETUPTOOLS_LICENSE = MIT
PYTHON3_SETUPTOOLS_LICENSE_FILES = LICENSE
PYTHON3_SETUPTOOLS_CPE_ID_VENDOR = python
PYTHON3_SETUPTOOLS_CPE_ID_PRODUCT = setuptools
PYTHON3_SETUPTOOLS_SETUP_TYPE = setuptools
HOST_PYTHON3_SETUPTOOLS_DL_SUBDIR = python-setuptools
HOST_PYTHON3_SETUPTOOLS_NEEDS_HOST_PYTHON = python3

$(eval $(host-python-package))
