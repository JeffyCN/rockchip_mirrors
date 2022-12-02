#!/bin/bash -e

if [ -z "$BASH_SOURCE" ];then
	echo "Not in bash, switching to it..."
	"$(find . -maxdepth 3 -name envsetup.sh | head -n 1 || echo /bin/bash)"
fi

choose_board()
{
	echo
	echo "You're building on Linux"
	echo "Lunch menu...pick a combo:"
	echo ""

	echo "0. non-rockchip boards"
	echo ${RK_DEFCONFIG_ARRAY[@]} | xargs -n 1 | sed "=" | sed "N;s/\n/. /"

	local INDEX
	while true; do
		read -p "Which would you like? [0]: " INDEX
		INDEX=$((${INDEX:-0} - 1))

		if [ "$INDEX" -eq -1 ]; then
			echo "Lunching for non-rockchip boards..."
			unset TARGET_OUTPUT_DIR
			unset RK_BUILD_CONFIG
			break;
		fi

		if echo $INDEX | grep -vq [^0-9]; then
			RK_BUILD_CONFIG="${RK_DEFCONFIG_ARRAY[$INDEX]}"
			[ -n "$RK_BUILD_CONFIG" ] && break
		fi

		echo
		echo "Choice not available. Please try again."
		echo
	done
}

lunch_rockchip()
{
	TARGET_DIR_NAME="$RK_BUILD_CONFIG"
	export TARGET_OUTPUT_DIR="$BUILDROOT_OUTPUT_DIR/$TARGET_DIR_NAME"

	mkdir -p "$TARGET_OUTPUT_DIR" || return 0

	echo "==========================================="
	echo
	echo "#TARGET_BOARD=`echo $RK_BUILD_CONFIG | cut -d '_' -f 2`"
	echo "#OUTPUT_DIR=output/$TARGET_DIR_NAME"
	echo "#CONFIG=${RK_BUILD_CONFIG}_defconfig"
	echo
	echo "==========================================="

	if [ $RK_DEFCONFIG_ARRAY_LEN -eq 0 ]; then
		echo "Continue without defconfig..."
		make -C "$BUILDROOT_DIR" O="$TARGET_OUTPUT_DIR" \
			olddefconfig &>/dev/null
		return 0
	fi

	make -C "$BUILDROOT_DIR" O="$TARGET_OUTPUT_DIR" \
		"${RK_BUILD_CONFIG}_defconfig"

	CONFIG="$TARGET_OUTPUT_DIR/.config"
	cp "$CONFIG" "$CONFIG.new"
	mv "$CONFIG.old" "$CONFIG" &>/dev/null || return 0

	make -C "$BUILDROOT_DIR" O="$TARGET_OUTPUT_DIR" olddefconfig &>/dev/null

	if ! diff "$CONFIG" "$CONFIG.new"; then
		read -t 10 -p "Found old config, override it? (y/n):" YES
		[ "$YES" = "n" ] || cp "$CONFIG.new" "$CONFIG"
	fi
}

bpkg()
{
	unset SCRIPT
	case "${1:-dir}" in
		configure|build|target_install|deploy)
			SCRIPT=.$1.sh
			DIR=$(bpkg dir $2)
			[ -x "$DIR/$SCRIPT" ] && "$DIR/$SCRIPT"
			;;
		dir)
			if [ -n "$2" ]; then
				find "$TARGET_OUTPUT_DIR/build/" -maxdepth 1 \
					-type d -name "*$2*" | head -n 1 || \
					echo "no pkg build dir for $2." >&2
			else
				echo $(realpath "$PWD") | \
					grep -oE "*/output/[^/]*/build/[^/]*" || \
					echo "not in a pkg build dir." >&2
			fi
			;;
		reconfig)
			shift
			bpkg configure $@ && bpkg build $@ && \
				bpkg target_install $@ && bpkg deploy $@
			;;
		rebuild)
			shift
			bpkg build $@ && bpkg target_install $@ && \
				bpkg deploy $@
			;;
		reinstall)
			shift
			bpkg target_install $@ && bpkg deploy $@
			;;
		*)
			bpkg dir $1
			;;
	esac
}

main()
{
	SCRIPTS_DIR="$(dirname "$(realpath "$BASH_SOURCE")")"
	BUILDROOT_DIR="$(dirname "$SCRIPTS_DIR")"
	BUILDROOT_OUTPUT_DIR="$BUILDROOT_DIR/output"
	TOP_DIR="$(dirname "$BUILDROOT_DIR")"
	echo "Top of tree: $TOP_DIR"

	RK_DEFCONFIG_ARRAY=(
		$(cd "$BUILDROOT_DIR/configs/"; ls rockchip_* | \
			grep "$(basename "$1")" | sed "s/_defconfig$//" | sort)
	)

	unset RK_BUILD_CONFIG
	RK_DEFCONFIG_ARRAY_LEN=${#RK_DEFCONFIG_ARRAY[@]}

	case $RK_DEFCONFIG_ARRAY_LEN in
		0)
			BOARD="$(echo "$1" | \
				sed "s#^\(output/\|\)rockchip_\([^/]*\).*#\2#")"
			RK_BUILD_CONFIG="${BOARD:+rockchip_$BOARD}"
			CONFIG="$BUILDROOT_OUTPUT_DIR/$RK_BUILD_CONFIG/.config"
			if [ ! -f "$CONFIG" ]; then
				unset RK_BUILD_CONFIG
				echo "No available configs${1:+" for: $1"}"
			fi
			;;
		1)
			RK_BUILD_CONFIG=${RK_DEFCONFIG_ARRAY[0]}
			;;
		*)
			if [ "$1" = ${RK_DEFCONFIG_ARRAY[0]} ]; then
				# Prefer exact-match
				RK_BUILD_CONFIG="$1"
			else
				choose_board
			fi
			;;
	esac

	[ -n "$RK_BUILD_CONFIG" ] || return

	lunch_rockchip

	# Set alias
	alias croot='cd "$TOP_DIR"'
	alias broot='cd "$BUILDROOT_DIR"'
	alias bout='cd "$TARGET_OUTPUT_DIR"'
	alias bmake='make -f "$TARGET_OUTPUT_DIR/Makefile"'

	alias bconfig='bpkg configure'
	alias bbuild='bpkg build'
	alias binstall='bpkg target_install'
	alias bdeploy='bpkg deploy'

	alias breconfig='bpkg reconfig'
	alias brebuild='bpkg rebuild'
	alias breinstall='bpkg reinstall'
	alias bupdate='bpkg reconfig'

	# The new buildroot Makefile needs make (>= 4.0)
	if "$BUILDROOT_DIR/support/dependencies/check-host-make.sh" 4.0 make >/dev/null; then
		return 0
	fi

	echo -e "\e[35mYour make is too old: $(make -v | head -n 1)\e[0m"
	echo "Please update it:"
	echo "git clone https://github.com/mirror/make.git"
	echo "cd make"
	echo "git checkout 4.2"
	echo "git am $BUILDROOT_DIR/package/make/*.patch"
	echo "autoreconf -f -i"
	echo "./configure"
	echo "make make -j8"
	echo "install -m 0755 make /usr/local/bin/make"
	return 1
}

IN_BUILDROOT_ENV="${TARGET_OUTPUT_DIR:+1}"

main "$@"

if [ "$BASH_SOURCE" == "$0" ];then
	# This script is executed directly
	[ -z "$IN_BUILDROOT_ENV" ] || exit 0

	echo -e "\e[35mEnter $BUILDROOT_DIR environment.\e[0m"
	/bin/bash
	echo -e "\e[35mExit from $BUILDROOT_DIR environment.\e[0m"
fi
