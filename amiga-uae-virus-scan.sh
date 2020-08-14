#!/bin/bash

# Ensure we have something to scan
if [ $# -lt 1 ]
then
	echo "Usage: $0 floppy-to-test.adf"
	echo "Usage: $0 directory-to-scan"
	exit 1
fi


# Ensure we have all native tools
if [ -z "$(which curl)" -o \
     -z "$(which lha)" -o \
     -z "$(which fs-uae)" -o \
     -z "$(which sha256sum)" ]
then
	echo -e "\033[1m\033[31mERROR:\033[0m"
	echo "This script requires the following programs to be in $PATH:"
	echo "  curl"
	echo "  lha"
	echo "  fs-uae"
	echo "  sha256sum"
	exit 1
fi


# Directories
CWD="$PWD"
INSTALLERS="$CWD/installers"
DHDIR=dh0


# Alias for curl
CURL="curl --progress-bar --location -o"




# Provide a way to bail.
# This does NOT clean up a running emulation session.
function int_func()
{
	tset
	echo "$0: Interrupt."
	exit 1
}
trap int_func INT


function colorprint()
{
	echo -en "\033[1m\033[3$1m"
	shift
	echo "$@"
	echo -en "\033[0m"
}
trap int_func INT



# Download any packages we don't have yet
function download_installers()
{
	colorprint 3 "Downloading missing components..."

	mkdir -p "$INSTALLERS"

	for n in $(cat installer_urls)
	do
		LHANAME=${n##*/}
		TXTNAME=${LHANAME%.lha}.readme

		if [ ! -e "$INSTALLERS/$LHANAME" ]
		then
			echo -e "\033[1m\033[34mDownloading\033[0m $LHANAME ..."
			$CURL "$INSTALLERS/$LHANAME" "$n"
		fi

		if [ ! -e "$INSTALLERS/$TXTNAME" ]
		then
			echo -e "\033[1m\033[34mDownloading\033[0m $TXTNAME ..."
			$CURL "$INSTALLERS/$TXTNAME" "${n%.lha}.readme"
		fi
	done

	colorprint 2 "...done"
	echo
}



# Checksum all files we get from Aminet
function verify_installers()
{
	colorprint 3 "Checking integrity..."

	if ! sha256sum --strict --quiet --check sha256sums
	then
		echo
		echo -e "\033[1m\033[31mERROR:\033[0m"
		echo "Integrity check failed."
		echo "Try removing the broken file and re-downloading it."
		echo "If you just downloaded these files, then maybe Aminet is currently having problems serving those files?"
		echo
		exit 1
	fi

	colorprint 2 "...done"
	echo
}



# This prepares a folder to be a virtual partition,
# with an Amiga system ready to run and scan a directory.
function populate_dh0()
{
	mkdir -p "$TD/$DHDIR"


	# Programs
	mkdir -p "$TD/$DHDIR/C"
	lha xqiw="$TD/$DHDIR/C" "$INSTALLERS"/CheckX.lha CheckX/CheckX
	lha xqiw="$TD/$DHDIR/C" "$INSTALLERS"/UAEquit.lha UAEquit


	# Libraries
	mkdir -p "$TD/$DHDIR/Libs"

	mkdir -p "$TD/$DHDIR/Libs/xad"
	lha xqiw="$TD/$DHDIR/Libs" "$INSTALLERS"/xadmaster000.lha xad/Libs/xadmaster.library
	lha xqiw="$TD/$DHDIR/Libs/xad" "$INSTALLERS"/xadmaster000.lha xad/Libs/xad/*

	mkdir -p "$TD/$DHDIR/Libs/xfd"
	lha xqiw="$TD/$DHDIR/Libs" "$INSTALLERS"/xfdmaster.lha xfd_User/Libs/xfdmaster.library
	lha xqiw="$TD/$DHDIR/Libs/xfd" "$INSTALLERS"/xfdmaster.lha xfd_User/Libs/xfd/*

	lha xqiw="$TD/$DHDIR/Libs" "$INSTALLERS"/xvslibrary.lha xvs/libs/xvs.library


	# Startup-sequence, config, registration keys
	mkdir -p "$TD/$DHDIR/S"
	lha xqiw="$TD/$DHDIR/S" "$INSTALLERS"/xadmaster-key.lha xadmaster.key

	cat > "$TD/$DHDIR/S/startup-sequence" <<-EOF
		;CheckX ALL FROM DF1: LOG SYS:checkx-scandir.log
		CheckX ALL FROM SYS:scandir LOG SYS:checkx-scandir.log
		UAEquit
	EOF
}



function write_uae_config()
{
	# Write main UAE config
	cat > "$TD/amiga-virus-scan.fs-uae" <<-EOF
		[fs-uae]
		amiga_model = A4000
		zorro_iii_memory = 1048576
		automatic_input_grab = 0
		end_config = 1
		expect_version = 2.8.0
		floppies_dir = ./
		#floppy_drive_1 = ./df1.adf
		fullscreen = 0
		hard_drive_0 = ./$DHDIR
		initial_input_grab = 0
		jit_compiler = 1
		joystick_port_0 = Mouse
		joystick_port_0_mode = mouse
		joystick_port_1 = none
		joystick_port_1_mode = nothing
		joystick_port_2 = none
		joystick_port_2_mode = none
		joystick_port_3 = none
		joystick_port_3_mode = none
		keep_aspect = 1
		maximized = 0
		save_disk = 0
		uae_sound_output = none
		video_sync = 1
		window_hidden = 0
		zoom = full
	EOF


	# Prevent FS-UAE from printing audio errors
	cat > "$TD"/.alsoftrc <<-EOF
		[general]
		drivers = null
	EOF
}




#
#
# Main script
#

colorprint 7 " *******************************************"
colorprint 7 "   Amiga virus scanner wrapper starting up"
colorprint 7 " *******************************************"
echo


# Get external Amiga software
download_installers
verify_installers


# Prepare emulation environment
colorprint 3 "Preparing emulation environment..."

TD="$(mktemp --directory)"
populate_dh0
write_uae_config

# Copy files to scan
colorprint 7 "Scan target: $1 (will be copied to emulation first)"

cp -r "$1" "$TD/$DHDIR/scandir"
chmod -R u+rwX "$TD/$DHDIR/scandir"

colorprint 2 "...done"
echo


# Run emulator
colorprint 3 "Running emulator..."
cd "$TD"
export HOME="$TD"
fs-uae amiga-virus-scan.fs-uae > /dev/null

colorprint 2 "...done"
echo


# Print results
echo
echo
colorprint 2 "Scan results:"
echo
cat ./dh0/checkx-scandir.log


# Clean up
cd ..
rm -rf "$TD"

echo
