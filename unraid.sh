#!/bin/bash
#

# unraid.sh
#
# by SpacinvaderOne 


# Variables
# 
# Variable - location of tools dir
TOOLS=/Macinabox/tools
# Variable - location of folder used to put os image in for full install.
IMAGE=/image/Macinabox
# Variable - location of folder used to put os image in for preparation install.
IMAGE2=/config/install_media
#
NAME=os_flavour
# VDISK= defined from third arguement
# End of variables


# Functions
# 
# Function - For full install - create vdisk based on size in template copy clover, ovmf, icon and xml to correct locations ready to run.
fullinstall() {
qemu-img create -f qcow2 /image/Macinabox/macos_disk.qcow2 $vdisksize
rsync -a --no-o /Macinabox/domainfiles/ /image/Macinabox/
rsync -a --no-o /Macinabox/xml/Macinabox.xml /xml/Macinabox.xml 
}

# Function - For preparation/manual install - Copy clover, ovmf, icon and xml to macinabox appdata folder on unraid ready to move manually.
prepareinstall() {
	rsync -a --no-o /Macinabox/domainfiles/ /config
	rsync -a --no-o /Macinabox/xml/Macinabox.xml /config/Macinabox.xml 

}

# Function - Convert downloaded image from .dmg to usuable .img image file and put in correct location
makeimg() {
"$TOOLS/dmg2img" "$TOOLS/FetchMacOS/BaseSystem/BaseSystem.dmg" "$DIR/$NAME.img"
}

# Function - check if directories needed are present for full install and if not create them
create_full() {
if [ ! -d $IMAGE ] ; then
		
			mkdir -vp $IMAGE
			echo "created folder Macinabox"
		else
			echo " folder Macinabox already present......continuing."
			
			fi	
			}
			
# Function - check if directories needed for preparation install are present and if not create them
create_prep() {
if [ ! -d $IMAGE2 ] ; then
		
mkdir -vp $IMAGE2
echo "created folder Macinabox in vm domain location"
else
echo " folder Macinabox already present......continuing."
			
fi	
}
						
# Function - print flag usage
print_usage() {
    echo
    echo "First flag sets macOS Flavour is downloaded to install"
	echo
    echo " -s, --high-sierra         Fetch & install High Sierra media."
    echo " -m, --mojave              Fetch & install Mojave media."
    echo " -c, --catalina            Fetch & install Catalina media."
	echo 
	echo "second flag sets install type"
	echo
    echo "     --full-install        Try to fully install on Unraid."
    echo "     --prepare-install     Prepare for manual install all files to appdata."
    echo
}
# Function - error

error() {
    local error_message="$*"
    echo "${error_message}" 1>&2;
}

#
# End of functions

# Check flag arguements and run accordingly

# Arguement uses variable set in template to choose which macOS version to use
argument="$1"
case $argument in
    -h|--help)
        print_usage
        ;;
    -s|--high-sierra)
		NAME=high-sierra-install
        "$TOOLS/FetchMacOS/fetch.sh" -p 091-95155 -c PublicRelease13 || exit 1;
        ;;
    -m|--mojave)
		NAME=mojave-install
        "$TOOLS/FetchMacOS/fetch.sh" -l -c PublicRelease14 || exit 1;
        ;;
    -c|--catalina|*)
		NAME=catalina-install
        "$TOOLS/FetchMacOS/fetch.sh" -l -c DeveloperSeed || exit 1;
        ;;
esac

# Arguement uses variable set in template to set whether to try a full install or just prepare files
argument="$2"
case $argument in
    --full-install)
        echo " full install to unraid domain location"
		create_full
		fullinstall
		DIR=$IMAGE
        ;;
    --prepare-install)
        echo " preparation of install media"
		create_prep
		prepareinstall
		DIR=$IMAGE2
        ;;
esac


# download image 
makeimg
