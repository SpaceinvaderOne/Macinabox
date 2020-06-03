#!/bin/bash
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  unraid.sh - Script used by Unraid docker conatainer to install a KVM virtual machine of different versions of macOS    # # 
# #  by - SpaceinvaderOne                                                                                                   # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# #  Full install Function - Creates ready to run the macOS installer, clover, vdisk ,ovmf and vm definition in defualt domains share # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  # # # # # 
currentDate=`date`
echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo "Starting process at $currentDate "
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo

fullinstall() {
	if [ ! -d $IMAGE ] ; then
		
				mkdir -vp $IMAGE
				echo "I have created the Macinabox directories"
			    echo "."
			    echo "."
			else
				echo "  Macinabox directories are already present......continuing."
			    echo "."
			    echo "."
			
				fi		


    if [ $TYPE == "raw" ] && [ ! -e $IMAGE/macos_disk.img ]; then
	
			qemu-img create -f raw /$IMAGE/macos_disk.img $vdisksize
			echo "."
			echo "Created vdisk as type raw"
			echo "."
			echo "."
	
		elif [ $TYPE == "qcow2" ] &&  [ ! -e $IMAGE/macos_disk.qcow2 ]; then
			qemu-img create -f qcow2 /$IMAGE/macos_disk.qcow2 $vdisksize
			echo "."
		    echo "Created vdisk as type qcow2"
			echo "."
			echo "."
		else
			echo "There is already a vdisk  image here...skipping"
			echo "."
			echo "."
			SKIPVDISK=yes

			fi
			
makeimg		
rsync -a --no-o /Macinabox/domainfiles/ $IMAGE
chmod -R 777 $IMAGE

if [ ! -e /xml/$XML ] ; then
rsync -a --no-o /Macinabox/xml/$TYPE/$XML /xml/$XML
chmod  777 /xml/$XML 
echo "vm template moved to server"
echo "."
echo "."

else
	vmtemplate=""
	echo "vm template was already present please manually delete it, if you want me to replace it"
	echo "."
	echo "."
	SKIPXML=yes
fi

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Prepare install Function - Creates macOS installer and all other files needed and place them in appdata folder ready for manual config of vm # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


prepareinstall() {
	if [ ! -d $IMAGE2 ] ; then
		
	mkdir -vp $IMAGE2
	echo "I have created the Macinabox directories"
    echo "."
    echo "."
else
	echo "  Macinabox directories are already present......continuing."
    echo "."
    echo "."

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
if [ ! -e $DIR/$NAME-install.img ] ; then
"/Macinabox/tools/dmg2img" "/Macinabox/tools/FetchMacOS/BaseSystem/BaseSystem.dmg" "$DIR/$NAME-install.img"
chmod 777 "$DIR/$NAME-install.img"
#cleanup
rm -r /Macinabox/tools/FetchMacOS/BaseSystem/*
else
SKIPIMG=yes
fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Pull High sierra if not already downloaded   # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
pullhsierra() {

	if [ ! -e /image/MacinaboxHighSierra/HighSierra-install.img ] ; then
		echo "I am going to download the HighSierra recovery media. Please be patient!"
	    echo "."
	    echo "."
    "/Macinabox/tools/FetchMacOS/fetch.sh" -p 041-91758  -c PublicRelease13 || exit 1;
else
	echo "Media already exists. I have already downloaded the High Sierra install media before"
    echo "."
    echo "."

fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Pull Mojave if not already downloaded   # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
pullmojave() {

	if [ ! -e /image/MacinaboxMojave/Mojave-install.img ] ; then
		echo "I am going to download the Mojave recovery media. Please be patient!"
	    echo "."
	    echo "."
    "/Macinabox/tools/FetchMacOS/fetch.sh" -p 061-26589  -c PublicRelease14 || exit 1;
else
	echo "Media already exists. I have already downloaded the Mojave install media before"
    echo "."
    echo "."

fi
}

	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Pull Catalina if not already downloaded   # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	pullcatalina() {

		if [ ! -e /image/MacinaboxCatalina/Catalina-install.img ] ; then
			echo "I am going to download the Catalina recovery media. Please be patient!"
		    echo "."
		    echo "."
	    "/Macinabox/tools/FetchMacOS/fetch.sh" -p 001-04366 -c PublicRelease || exit 1;
	else
		echo "Media already exists. I have already downloaded the Catalina install media before"
	    echo "."
	    echo "."

	fi
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
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo 	
	echo "Summary of what has been done"
    echo 
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "."
	echo "."
	echo "The reference /image below refers to where you mapped that folder in the docker template on your server "
    echo "(normally to /mnt/user/domains)"
	echo "."
	echo "."
		if [ "$SKIPIMG" = "yes" ] ; then
    echo "Install media was already present"
else
	echo "MacOS install media was put in $DIR/$NAME-install.img"
fi
	echo "."
	echo "."
		if [ "$SKIPVDISK" = "yes" ] ; then
    echo "Vdisk was already present"
else
	echo "A $TYPE Vdisk of $vdisksize was created in $IMAGE "
fi
    echo "."
    echo "."
    echo "Uptodate clover image was put in $IMAGE"
    echo "."
	echo "."
    echo "Compatible OVMF files vere put in $IMAGE/ovmf"
	echo "."
	echo "."
	if [ "$SKIPXML" = "yes" ] ; then
		echo "An XML file was already present for Macinabox$NAME you will need to manually delete if you want me to replace this"
else
	echo "XML template file for the vm was placed in Unraid system files. This file assumes your vm path"
	echo "is /mnt/user/domains if it isnt you will need to manually edit the template changing the locations accordingly"
fi
	echo "."
	echo "."
	echo "OK process has finished at $currentDate "
	if [ "$SKIPXML" = "yes" ] ; then
	echo "."
else
	echo "."
	echo "."
    echo "Now you must stop and start the array. The vm will be visible in the Unraid VM manager"
	
	fi
		
	
}

print_result2() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "."	
	echo "Summary of what has been done"
    echo "."
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "."
    echo "MacOS inatall media was put in $DIR/$NAME-install.img"
	echo
    echo "No Vdisk was created. You will need to manaually do this as prepare option was set in docker container template"
    echo 
    echo "Compatible OVMF files vere put in /mnt/user/appdata/Macinabox/ovmf"
	echo 
	echo "XML template file for the vm was placed in /mnt/user/appdata/Macinabox"
	echo
    echo "Everything is now prepared. You need to move files to correct place yourself and edit/copy xml then start the install"
	echo "."
	echo "."
	echo "OK process has finished at $currentDate "
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
		pullhsierra
		;;
    -m|--mojave)
		XML=MacinaboxMojave.xml
		NAME=Mojave
		pullmojave
        ;;
    -c|--catalina|*)
		XML=MacinaboxCatalina.xml
		NAME=Catalina
		pullcatalina
        ;;
		
	
esac

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Process second flag sent from the Unraid docker container tempate - chooses whether a full or preparation install  # # # # # # # # # # # # # #   
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


argument="$2"
case $argument in
    --full-install)
		IMAGE=/image/Macinabox$NAME
		DIR=$IMAGE
		echo " Full install starting to unraid domain $IMAGE"
		echo "."
		echo "."
		fullinstall
		print_result1
        ;;
    --prepare-install)
        echo " preparation of install media"
		echo "."
		echo "."
		IMAGE2=/config/install_media/$NAME
		DIR=$IMAGE2
		prepareinstall
		print_result2
		
        ;;
esac







