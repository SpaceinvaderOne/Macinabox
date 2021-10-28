#!/bin/bash
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  unraid.sh - Script used by Macinabox docker conatainer to install a KVM virtual machine of different versions of macOS    # # 
# #  by - SpaceinvaderOne                                                                                                   # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Chooses whether a full or preparation install  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

automanual() {
		
if [ "$vminstall" == "Auto install" ] ; then # check if template set to auto install
	echo "."
	echo "."
	autoinstall #run function autoinstall
	print_result_autoinstall #print results
elif [ "$vminstall" == "Manual install" ] ; then # check if template set to manual install
    echo " Manual install starting"
	echo "."
	echo "."
	manualinstall  #run function manual install
	print_result_manualinstall  #print results
else
	echo "I dont know what type of install you want me to do? Is your template correct?"
fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# #  Auto install Function - Creates ready to run the macOS installer, OpenCore, vdisk  and vm definition in defualt domains share # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  # # # # # 


autoinstall() {
	mkdir -vp /config/autoinstall/ # create folder for vm xml generation
	#check there is a folder in the domains share named the version of the macOS being installed. If not create it
	if [ ! -d "$DOMAIN" ] ; then
		
				mkdir -vp "$DOMAIN"
				echo "I have created the Macinabox directories"
			    echo "."
			    echo "."
			#if it was already present continue and print message
			else
				echo "  Macinabox directories are already present......continuing."
			    echo "."
			    echo "."
			
				fi		

    # check if a vdisk is present to install macOS on. If not create one
    if [ ! -e "$DOMAIN"/macos_disk.img ]; then
	
			qemu-img create -f raw "$DOMAIN"/macos_disk.img "$vdisksize"
			echo "."
			echo "Created vdisk"
			echo "."
			echo "."
        #if it was already present continue and print message
		else
			echo "There is already a vdisk  image here...skipping"
			echo "."
			echo "."
			SKIPVDISK=yes

			fi
 makeimg #convert dmg and put in iso share			
 makeopencore #extract and move Opencore to isos share
 addxml
 fixxml
 chmod -R 777 "$DOMAIN"/ # reset permissions
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Manual install Function - Creates macOS installer & bootload puts in isos share. Puts other files needed for vm in appdata folder # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

manualinstall() {
			
	makeimg #convert dmg and put in iso share
    makeopencore #extract and move Opencore to isos share
	fixxml
	chmod -R 777 /config2/ #reset permissions on macinabox folder in appdata	

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Covert DMG to IMG Function - Converts the downloaded macOS Baseimage as .dmg to a usable .img format   # # # # # # # # # # # # # # # # # # # #  
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

makeimg() {
# check if install image has previously been created and if not convert baseimage and put in iso share
if [ ! -e /isos/"$NAME"-install.img ] ; then
dmg2img "/Macinabox/tools/FetchMacOS/BaseSystem/BaseSystem.dmg" "/isos/$NAME-install.img"
touch /config2/install_media_is_in_isos_share # make a file showing user where install media is located
chmod 777 "/isos/$NAME-install.img"
#cleanup - remove baseimage from macinabox appdata now its been converted and moved
rm -r /Macinabox/tools/FetchMacOS/BaseSystem/*
else
SKIPIMG=yes
fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Extract and move Opencore to the iso share   # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
makeopencore() {
    # check if Opencore is already present if not extract and move to isos share
	if [ ! -e /isos/"$NAME"-opencore.img ] ; then
		echo "Putting open core in the isos share"

		rsync -a --no-o /Macinabox/bootloader/ /config2 #put opencore zip in mac appdata
		unzip -d /config2/ /config2/OpenCore.img.zip #extract opencore to usable .img file
		rsync -a --no-o /config2/OpenCore.img /isos/"$NAME"-opencore.img # Move opencore to isos share
		chmod 777 /isos/"$NAME"-opencore.img #reset permissions on opencore image
		touch /config2/opencore_is_in_isos_share # make a file showing user where Opencore is located
		rm /config2/OpenCore.img.zip && rm /config2/OpenCore.img #cleanup - delete temp opencore files now its been extracted and moved
else
	# if opencore was already present skip and print message
	echo "$NAME-opencore.img already exists. If you want me to replace you will need to manually delete it first"
    echo "."
    echo "."

fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Try to directly inject macinabox helper userscript     # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
fixxml() {
    
	rsync -a --no-o /Macinabox/tools/fixxml/ /config2/ # copy macinabox helper data to macinabox appdata
		
if [ "$injectfixxml" == "yes" ] && [ ! -e /userscripts/1_macinabox_helper ]; then
		echo "Trying to add userscript"

		unzip -d /userscripts/ /config2/1_macinabox_helper.zip #extract macinabox helper userscript into userscript location
		unzip -d /userscripts/ /config2/1_macinabox_vmready_notify.zip #extract macinabox notify userscript into userscript location
		rm /config2/1_macinabox_helper.zip #cleanup delete zip file
		rm /config2/1_macinabox_vmready_notify.zip #cleanup delete zip file
		chmod -R 777 "/userscripts/1_macinabox_helper/" && chmod 777 /config2/macinabox_helper_userscript.sh #reset permissions on user script
		chmod -R 777 "/userscripts/1_macinabox_vmready_notify/" && chmod 777 /config2/macinabox_vmready_notify.sh #reset permissions on user script
		echo "Injected macinabox helper and notify userscript into user script plugins and a copy of macinabox helper and notify script has been put in appdata"			
else
	# leave userscript in macinabox appdata & delete zip file
	rm /config2/1_macinabox_helper.zip #cleanup delete zip file
	rm /config2/1_macinabox_vmready_notify.zip #cleanup delete zip file
	chmod 777 /config2/macinabox_helper_userscript.sh #reset permissions on user script
	chmod 777 /config2/macinabox_vmready_notify.sh #reset permissions on user script
	echo "A copy of macinabox helper and notify script has been put in appdata"

fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # Adds xml to Unraid (autoinstall) and/or sample xml to appdata (auto and manual install)# # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
addxml() {
	
if [ ! -e /customovmf/Macinabox_CODE-pure-efi.fd ] ; then
	rsync -a --no-o /Macinabox/ovmf/ /customovmf/
	chmod -R 777 /customovmf/
fi

if [ ! -e /config/autoinstall/"$XML".xml ] ; then
	sed "s?XXXX?$VMIMAGES?" </Macinabox/xml/"$XML".xml >/tmp/tempxml.xml
	sed "s?YYYY?$ISOIMAGES?" </tmp/tempxml.xml > /config/autoinstall/"$XML".xml
	chmod 777 /config/autoinstall/"$XML".xml
	echo "macOS VM template generated and moved to server (You need to run macinabox_helper userscript)"
	echo "."
	echo "."
	rsync -a --no-o /config/autoinstall/"$XML".xml /config2/"$XML"_original.xml #put an original backup of xml file in macinabox appdata

else
	echo "vmacOS VM template was already present. Please manually delete it, if you want me to replace it"
	echo "."
	echo "."
	SKIPXML=yes
fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Pull High sierra if not already downloaded   # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
pullhsierra() {

	if [ ! -e /isos/HighSierra-install.img ] ; then
		echo "I am going to download the HighSierra recovery media. Please be patient!"
	    echo "."
	    echo "."
    "/Macinabox/tools/FetchMacOS/fetch.sh" -v 10.13 -k BaseSystem || exit 1;
else
	echo "Media already exists. I have already downloaded the High Sierra install media before"
    echo "."
    echo "."

fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Pull Mojave if not already downloaded      # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
pullmojave() {

	if [ ! -e /isos/Mojave-install.img ] ; then
		echo "I am going to download the Mojave recovery media. Please be patient!"
	    echo "."
	    echo "."
         "/Macinabox/tools/FetchMacOS/fetch.sh" -v 10.14 -k BaseSystem || exit 1;
else
	echo "Media already exists. I have already downloaded the Mojave install media before"
    echo "."
    echo "."

fi
}

	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Pull Catalina if not already downloaded    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	pullcatalina() {

		if [ ! -e /isos/Catalina-install.img ] ; then
			echo "I am going to download the Catalina recovery media. Please be patient!"
		    echo "."
		    echo "."
	    "/Macinabox/tools/FetchMacOS/fetch.sh" -v 10.15 -k BaseSystem || exit 1;
	else
		echo "Media already exists. I have already downloaded the Catalina install media before"
	    echo "."
	    echo "."

	fi
	}
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Pull BigSur if not already downloaded    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 	
	
	pullbigsur() {

		if [ ! -e /isos/BigSur-install.img ] ; then
			echo "I am going to download the BigSur recovery media. Please be patient!"
		    echo "."
		    echo "."
	    "/Macinabox/tools/FetchMacOS/fetch.sh" -v 10.16 -c PublicRelease -p 002-23589 || exit 1;
		
	else
		echo "Media already exists. I have already downloaded the Big Sur install media before"
	    echo "."
	    echo "."

	fi
	
	}
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Extract BigSur from InstallAssistant.pkg if using script1    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
			
	
	extractbigsur() {
		if [ "$method" = "method 1" ] ; then
		echo " Nothing to extract using method 1"
		else
		7z e -txar -o/Macinabox/tools/FetchMacOS/BaseSystem/ /Macinabox/tools/FetchMacOS/BaseSystem/InstallAssistant.pkg '*.dmg' 
		rm /Macinabox/tools/FetchMacOS/BaseSystem/InstallAssistant.pkg
		7z e -tdmg -o/Macinabox/tools/FetchMacOS/BaseSystem/ /Macinabox/tools/FetchMacOS/BaseSystem/SharedSupport.dmg 5.hfs
		rm /Macinabox/tools/FetchMacOS/BaseSystem/SharedSupport.dmg
		mkdir /Macinabox/tools/FetchMacOS/BaseSystem/temp
		mount -t hfsplus -oloop /Macinabox/tools/FetchMacOS/BaseSystem/*.hfs /Macinabox/tools/FetchMacOS/BaseSystem/temp
		7z e -o/Macinabox/tools/FetchMacOS/BaseSystem/ /Macinabox/tools/FetchMacOS/BaseSystem/temp/*MacSoftwareUpdate/*.zip AssetData/Restore/Base*.dmg
		umount /Macinabox/tools/FetchMacOS/BaseSystem/temp && rm -r /Macinabox/tools/FetchMacOS/BaseSystem/temp && rm /Macinabox/tools/FetchMacOS/BaseSystem/*.hfs
		fi		
	}		
						
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Print result Function - Prints info where all files went                                                     # # # # # # # # # # # # # # # # #  
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

print_result_autoinstall() {
  
    echo ""	
	echo "Summary of what has been done"
    echo 
    echo "."
	echo "."
	echo "The reference /domains below refers to where you mapped that folder in the docker template on your server "
    echo "(normally to /mnt/user/domains)"
	echo "."
	echo "."
		if [ "$SKIPIMG" = "yes" ] ; then
    echo "Install media was already present"
else
	echo "MacOS install media was put in your Unraid isos share named $NAME-install.img"
fi
	echo "."
	echo "."
		if [ "$SKIPVDISK" = "yes" ] ; then
    echo "Vdisk was already present"
else
	echo "A  Vdisk of "$vdisksize" was created in "$DOMAIN" "
fi
    echo "."
    echo "."
    echo "OpenCore bootloader image was put in your Unraid isos share named"$NAME"-opencore.img"
    echo "."
	echo "."
    echo "Custom ovmf files are in /mnt/user/system/custom_ovmf"
	echo "."
	echo "."
	if [ "$SKIPXML" = "yes" ] ; then
		echo "An XML file was already present for Macinabox"$NAME" you will need to manually delete if you want me to replace this"
else
	echo "XML template file for the vm is ready for install with macinabox helper user script."
	echo "Note  This file assumes your vm share is the default location /mnt/user/domains"
	echo "If it isnt you will need to change the locations accordingly after in unraid vm manager before running vm"
fi

if [ "$injextfixxml" = "yes" ] ; then
    echo "The fix script should be in the userscripts plugin now"
	echo "But you will also find a copy of the custom xml fix script in /mnt/user/appdata/macinabox/macinabox"
else
	echo "A copy of the macinabox helper user script was placed in /mnt/user/appdata/macinabox/macinabox"
fi
	echo "."
	echo "."
	echo "OK process is now complete "
    echo "Now you must stop and start the array. The vm will be visible in the Unraid VM manager"
				
}

print_result_manualinstall() {
    echo "."	
	echo "Summary of what has been done"
    echo "."
    echo "."
    echo "MacOS install media was put in your Unraid isos share named $NAME-install.img"
	echo "OpenCore bootloader image was put in your Unraid isos share named "$NAME"-opencore.img"
	
if [ "$injextfixxml" = "yes" ] ; then
    echo "The macinabox helper script should be in the userscripts plugin now"
	echo "But you will also find a copy of the macinabox helper script in /mnt/user/appdata/macinabox/macinabox"
else
	echo "The macinabox helper script was placed in /mnt/user/appdata/macinabox/macinabox"
fi
	
	echo ""
    echo "Everything is now prepared ready to manually set up"
	
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Error Function # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

error() {
    local error_message="$*"
    echo "${error_message}" 1>&2;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Start the process and chooses which macOS version to download    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


		
if [ "$flavour" == "Catalina" ] ; then
	XML="Macinabox Catalina"
	NAME="Catalina"
	DOMAIN=/domains/"$XML"
	pullcatalina
	automanual
elif [ "$flavour" == "Big Sur" ] ; then	
    XML="Macinabox BigSur"
	NAME="BigSur"
	DOMAIN=/domains/"$XML"
	pullbigsur && extractbigsur
    automanual
elif [ "$flavour" == "Mojave" ] ; then
	XML="Macinabox Mojave"
	NAME="Mojave"
	DOMAIN=/domains/"$XML"
	pullmojave
	automanual
elif [ "$flavour" == "High Sierra" ] ; then
	XML="Macinabox HighSierra"
	NAME="HighSierra"
	DOMAIN=/domains/"$XML"
	pullhsierra
	automanual				
else
	echo "I dont know what OS to try and download? Is your template correct?"

fi
exit
			

