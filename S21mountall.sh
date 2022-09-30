#!/bin/sh

# Uncomment below to see more logs
# set -x

case "$1" in
	start|"")
		mount-helper
		;;
	restart|reload|force-reload)
		echo "Error: argument '$1' not supported" >&2
		exit 3
		;;
	stop|status)
		# No-op
		;;
	*)
		echo "Usage: [start|stop]" >&2
		exit 3
		;;
esac

:
