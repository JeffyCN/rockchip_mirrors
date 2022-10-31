#!/bin/bash
#
# Usage:
# update_defconfig.sh <defconfig> [output dir]

set -e

BOARD="$(basename "${1%_defconfig}")"
[ -n "$BOARD" ] || exit 1

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
BUILDROOT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${2:-$BUILDROOT_DIR/output/$BOARD}"
cd "$BUILDROOT_DIR"

DEFCONFIG="configs/${BOARD}_defconfig"
[ -r "$DEFCONFIG" ] || exit 1

echo "Updating defconfig: $DEFCONFIG"

CONFIG="$OUTPUT_DIR/.config"
ORIG_CONFIG="$OUTPUT_DIR/.config.orig"
ORIG_DEFCONFIG="$OUTPUT_DIR/.defconfig"
BASE_DEFCONFIG="$OUTPUT_DIR/.base_defconfig"
NEW_DEFCONFIG="$OUTPUT_DIR/.new_defconfig"
FRAGMENT="$OUTPUT_DIR/.fragment"

if [ ! -r "$CONFIG" ]; then
	mkdir -p "$OUTPUT_DIR"
	"$SCRIPT_DIR/parse_defconfig.sh" "$DEFCONFIG" "$CONFIG"
fi

cat "$CONFIG" > "$ORIG_CONFIG"

make O="$OUTPUT_DIR" olddefconfig >/dev/null
sed -i "s~\(^BR2_DEFCONFIG=\).*~\1\"$ORIG_DEFCONFIG\"~" "$CONFIG"
make O="$OUTPUT_DIR" savedefconfig >/dev/null
echo "Original defconfig saved to $ORIG_DEFCONFIG"

# Generate base defconfig
grep "^#include " $DEFCONFIG > "$FRAGMENT"
"$SCRIPT_DIR/parse_defconfig.sh" "$FRAGMENT" "$CONFIG" > /dev/null
make O="$OUTPUT_DIR" olddefconfig >/dev/null
sed -i "s~\(^BR2_DEFCONFIG=\).*~\1\"$BASE_DEFCONFIG\"~" "$CONFIG"
make O="$OUTPUT_DIR" savedefconfig >/dev/null
echo "Base defconfig saved to $BASE_DEFCONFIG"

cat "$ORIG_CONFIG" > "$CONFIG"

# Update defconfig fragment
SED_CONFIG_EXP1="s/^\(<\|>\) \([a-zA-Z0-9_]*\)=.*/\2/p"
SED_CONFIG_EXP2="s/^\(<\|>\) # \([a-zA-Z0-9_]*\) is not set$/\2/p"
SED_STRING_EXP="s/^.*=\"\(.*\)\"/\1/p"

CFG_LIST=$(diff "$ORIG_DEFCONFIG" "$BASE_DEFCONFIG" | \
	sed -n -e "$SED_CONFIG_EXP1" -e "$SED_CONFIG_EXP2" | sort | uniq)

if [ -z "$CFG_LIST" ]; then
	echo "Already up-to-date."
	exit 0
fi

for CFG in $CFG_LIST ; do
	BASE_VAL=$(grep -w $CFG "$BASE_DEFCONFIG" || true)
	ORIG_NEW_VAL=$(grep -w $CFG "$ORIG_DEFCONFIG" || true)

	if [ -z "$ORIG_NEW_VAL" ]; then
		# Reset to default
		NEW_VAL="$CFG="
	else
		# Replace
		NEW_VAL="$ORIG_NEW_VAL"

		if grep -q "^$CFG+=" "$DEFCONFIG"; then
			BASE_STR=$(echo "$BASE_VAL" | sed -n "$SED_STRING_EXP")
			NEW_STR=$(echo "$NEW_VAL" | sed -n "$SED_STRING_EXP")
			if [ -n "$BASE_STR" -a -n "$NEW_VAL" ]; then
				# Try to extract additional strings
				for s in $BASE_STR; do
					NEW_STR=$(echo "$NEW_STR" | \
						xargs -n 1 | grep -v "^$s$" | \
						xargs)
				done

				NEW_VAL="${NEW_STR:+$CFG+=\"$NEW_STR\"}"
			fi
		fi
	fi

	echo "$NEW_VAL" >> $FRAGMENT

	echo "Value of $CFG applied to fragment:"
	echo -e "Base value:\t$BASE_VAL"
	if [ "$NEW_VAL" != "$ORIG_NEW_VAL" ]; then
		echo -e "New value:\t$ORIG_NEW_VAL"
	fi
	echo -e "Final value:\t$NEW_VAL"
	echo
done

cat $FRAGMENT > $DEFCONFIG

# Update defconfig fragment for dependency changes
cat "$CONFIG" > "$ORIG_CONFIG"
"$SCRIPT_DIR/parse_defconfig.sh" "$DEFCONFIG" "$CONFIG" > /dev/null
make O="$OUTPUT_DIR" olddefconfig >/dev/null
sed -i "s~\(^BR2_DEFCONFIG=\).*~\1\"$NEW_DEFCONFIG\"~" "$CONFIG"
make O="$OUTPUT_DIR" savedefconfig >/dev/null
cat "$ORIG_CONFIG" > "$CONFIG"

CFG_LIST=$(diff "$ORIG_DEFCONFIG" "$NEW_DEFCONFIG" | \
	sed -n -e "$SED_CONFIG_EXP1" -e "$SED_CONFIG_EXP2" | sort | uniq)
for CFG in $CFG_LIST ; do
	if ! grep -q -w $CFG $DEFCONFIG; then
		echo "$CFG=" >> $DEFCONFIG
	fi
done

# Verify defconfig fragment
"$SCRIPT_DIR/parse_defconfig.sh" "$DEFCONFIG" "$CONFIG" > /dev/null
make O="$OUTPUT_DIR" olddefconfig >/dev/null
sed -i "s~\(^BR2_DEFCONFIG=\).*~\1\"$NEW_DEFCONFIG\"~" "$CONFIG"
make O="$OUTPUT_DIR" savedefconfig >/dev/null
cat "$ORIG_CONFIG" > "$CONFIG"
if diff "$ORIG_DEFCONFIG" "$NEW_DEFCONFIG" | grep ""; then
	echo "Configs unmatched, might be something wrong."
fi

echo "Done updating $DEFCONFIG."
