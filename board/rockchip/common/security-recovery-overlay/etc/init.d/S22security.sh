#!/bin/sh

set -e

/usr/bin/tee-supplicant &

/usr/bin/updateEngine --misc_custom read
/usr/bin/updateEngine --misc_custom clean

mv /tmp/custom_cmdline /tmp/syspw &&

/usr/bin/keybox_app && rm /tmp/syspw
