#!/bin/bash
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  unraid.sh - Script used by Unraid docker conatainer to install a KVM virtual machine of different versions of macOS    # # 
# #  by - SpaceinvaderOne                                                                                                   # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# #  Full install Function - Creates ready to run the macOS installer, clover, vdisk ,ovmf and vm definition in defualt domains share # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  # # # # # 

fullinstall() {
	if [ ! -d $IMAGE ] ; then
		
				mkdir -vp $IMAGE
				echo "created  Macinabox directories"
			else
				echo "  Macinabox directories already present......continuing."
			
				fi		
	

    if [ $TYPE == "raw" ] ; then
	
			qemu-img create -f raw /$IMAGE/macos_disk.img $vdisksize
			echo "created vdisk as raw"
		else
			qemu-img create -f qcow2 /$IMAGE/macos_disk.qcow2 $vdisksize
		    echo "created vdisk as qcow2"
			fi	
makeimg		
rsync -a --no-o /Macinabox/domainfiles/ $IMAGE
rsync -a --no-o /Macinabox/xml/$TYPE/$XML /xml/$XML
chmod -R 777 $IMAGE
chmod  766 /xml/$XML 

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Prepare install Function - Creates macOS installer and all other files needed and place them in appdata folder ready for manual config of vm # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


prepareinstall() {
	if [ ! -d $IMAGE2 ] ; then
		
	mkdir -vp $IMAGE2
	echo "created  Macinabox dirs in vm domain location"
	else
	echo "  Macinabox dirs already present......continuing."
			
	fi		
	
	makeimg
	rsync -a --no-o /Macinabox/domainfiles/ /config
	rsync -a --no-o /Macinabox/xml/$TYPE/$XML /config/$XML
	chmod -R 777 /config/

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Covert DMD to IMG Function - Coverts the download macOS Baseimage as .dmg to a usable .img format   # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
makeimg() {
"/Macinabox/tools/dmg2img" "/Macinabox/tools/FetchMacOS/BaseSystem/BaseSystem.dmg" "$DIR/$NAME-install.img"
chmod 777 "$DIR/$NAME-install.img"
#cleanup
rm -R /Macinabox/tools/FetchMacOS/BaseSystem
}

						
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Print usage Function - Prints info on flags used which are passed from the Unraid docker container template  # # # # # # # # # # # # # # # # #  
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

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

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Print result Function - Prints info where all files went                                                     # # # # # # # # # # # # # # # # #  
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

print_result1() {
	echo
	echo
	echo "the reference /image below refers to where you mapped that folder on your server (normally to /mnt/user/doamins)"
    echo
    echo "MacOS install media was put in $DIR/$NAME-install.img"
	echo
    echo "A $TYPE Vdisk of $vdisksize was created in $IMAGE "
    echo 
    echo "Compatible OVMF files vere put in $IMAGE/ovmf"
	echo 
	echo "XML template file for the vm was placed in Unraid system files and will show in vm manager after array has been stopped and restarted"
	echo
    echo "Now you must stop and start the array. Then start the vm and the install will start"
	echo
}

print_result2() {
	echo
	echo
    echo
    echo "MacOS inatall media was put in $DIR/$NAME-install.img"
	echo
    echo "No Vdisk was created. You will need to manaually do this as prepare option was set in docker container template"
    echo 
    echo "Compatible OVMF files vere put in /mnt/user/appdata/Macinabox/ovmf"
	echo 
	echo "XML template file for the vm was placed in /mnt/user/appdata/Macinabox"
	echo
    echo "So everything is prepared. You need to move files to correct place yourself and edit/copy xml then start the install"
	echo
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Error Function # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

error() {
    local error_message="$*"
    echo "${error_message}" 1>&2;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Process first flag sent from the Unraid docker container tempate - chooses which macOS version to download   # # # # # # # # # # # # # # # # #  
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


argument="$1"
case $argument in
    -h|--help)
        print_usage
        ;;
    -s|--high-sierra)
		XML=MacinaboxHighSierra.xml
		NAME=HighSierra
        "/Macinabox/tools/FetchMacOS/fetch.sh" -p 041-91758  -c PublicRelease13 || exit 1;
        ;;
    -m|--mojave)
		XML=MacinaboxMojave.xml
		NAME=Mojave
        "/Macinabox/tools/FetchMacOS/fetch.sh" -p 061-26589  -c PublicRelease14 || exit 1;
        ;;
    -c|--catalina|*)
		XML=MacinaboxCatalina.xml
		NAME=Catalina
        "/Macinabox/tools/FetchMacOS/fetch.sh" -l -c PublicRelease || exit 1;
        ;;
    -d|--catalinabeta)
		XML=MacinaboxCatalina.xml
		NAME=Catalina
        "/Macinabox/tools/FetchMacOS/fetch.sh" -p 061-32950 -c DeveloperSeed || exit 1;
        ;;
		
	
esac

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Process second flag sent from the Unraid docker container tempate - chooses whether a full or preparation install  # # # # # # # # # # # # # #   
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


argument="$2"
case $argument in
    --full-install)
        echo " full install to unraid domain location"
		IMAGE=/image/Macinabox$NAME
		DIR=$IMAGE
		fullinstall
		print_result1
        ;;
    --prepare-install)
        echo " preparation of install media"
		IMAGE2=/config/install_media/$NAME
		DIR=$IMAGE2
		prepareinstall
		print_result2
		
        ;;
esac







