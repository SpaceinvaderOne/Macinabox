#!/bin/bash
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  unraid.sh - Script used by Macinabox docker conatainer to install a KVM virtual machine of different versions of macOS    # # 
# #  by - SpaceinvaderOne                                                                                                   # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Chooses whether a full or preparation install  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
umask 0000
automanual() {
		
if [ "$vminstall" == "Auto install" ] ; then # check if template set to auto install
	echo "."
	echo "."
	vdisktype #run function to install either qcow2 or raw vdisk
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
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# #  Selects if vdisk choosen is qcow2 or raw  # #  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  # # # # # 


vdisktype() {

#if vdisk was set as qcow2 then run autoinstall using qcow2 vdisk type
if [ "$vdisktype" == "qcow2" ] ; then
	autoinstall_qcow2
				
#if vdisk was not set as qcow2 then run autoinstall using raw vdisk
#set vdisk type to raw in case docker template is old and doest have vdisk type option
else
	vdisktype="raw"
	autoinstall_raw
				
fi		

}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# #  Auto install raw vdisk Function - Creates ready to run the macOS installer, OpenCore, vdisk  and vm definition in defualt domains share # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  # # # # # 


autoinstall_raw() {
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

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# #  Auto install qcow2 vdisk Function - Creates ready to run the macOS installer, OpenCore, vdisk  and vm definition in defualt domains share # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  # # # # # 


autoinstall_qcow2() {
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
	
			qemu-img create -f qcow2 "$DOMAIN"/macos_disk.img "$vdisksize"
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
	opencorelocation="$ISOIMAGES"
    makeopencore #extract and move Opencore to isos share
	fixxml
	chmod -R 777 /config/ #reset permissions on macinabox folder in appdata	

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Covert DMG to IMG Function - Converts the downloaded macOS Baseimage as .dmg to a usable .img format   # # # # # # # # # # # # # # # # # # # #  
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

makeimg() {
# check if install image has previously been created and if not convert baseimage and put in iso share
if [ ! -e /isos/"$NAME"-install.img ] ; then
qemu-img convert "/config/baseimage_temp/BaseSystem.dmg" -O raw "/isos/$NAME-install.img"
touch /config/install_media_is_in_isos_share # make a file showing user where install media is located
chmod 777 "/isos/$NAME-install.img"
#cleanup - remove baseimage from macinabox appdata now its been converted and moved
rm /config/baseimage_temp/BaseSystem.dmg
rm /config/baseimage_temp/BaseSystem.chunklist
else
SKIPIMG=yes
fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Extract and move stock Opencore to the vm share   # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
makeopencorestock() {
	# check if Opencore is already present if not extract and move to isos share
	    
	if [ ! -e "$DOMAIN"/"$NAME"-opencore.img ] ; then
		echo "Putting stock open core in the vm share"

		unzip -d /config/ /Macinabox/bootloader/OpenCore*.img.zip #extract opencore to usable .img file
		rsync -a --no-o /config/OpenCore*.img "$opencorelocation"/"$NAME"-opencore.img  # Move opencore to vm share for auto install or iso share for manual
		chmod 777 "$opencorelocation"/"$NAME"-opencore.img  #reset permissions on opencore image
		touch /config/opencore_is_in_vms_share # make a file showing user where Opencore is located
		rm /config/OpenCore*.img #cleanup 
		

				
else
	# if opencore was already present skip and print message
	echo "$NAME-opencore.img already exists. If you want me to replace you will need set 'replaceopencore' to yes in the template"
    echo "."
    echo "."

fi
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Extract and move custom Opencore to the vm share   # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

makeopencorecustom() {
	
	if [ ! -d /config/custom_opencore ] ; then
		mkdir -vp /config/custom_opencore && cp /Macinabox/custom_opencore/readme.txt /config/custom_opencore/readme.txt
	fi
	
	# check if Opencore is already present if not extract and move to isos share
	    
	if [ ! -e "$DOMAIN"/"$NAME"-opencore.img ] ; then
	
	
	# check if custom Opencore is present  
	for file in /config/custom_opencore/*.gz
	do	    
	if [  -e "$file" ]; then 
		echo "extracting custom Opencore"
		gunzip -dk /config/custom_opencore/ /config/custom_opencore/*.gz #extract opencore
		echo "Putting custom Opencore in the vm share"
			rsync -a --no-o /config/custom_opencore/*.iso "$DOMAIN"/"$NAME"-opencore.img # Move custom opencore to vm share
			chmod 777 "$DOMAIN"/"$NAME"-opencore.img #reset permissions on opencore image
			rm /config/custom_opencore/*.iso #cleanup
		
		else
				echo "No custom Opencore present in /appdata/macinabox/custom_opecore I will continue and use stock version"
			makeopencorestock  # if no custom Opencore available then use stock
		fi

	done
else
	# if opencore was already present skip and print message
	echo "$NAME-opencore.img already exists. If you want me to replace you will need set 'replaceopencore' to yes in the template"
    echo "."
    echo "."

fi


}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # Use stock or custom opencore  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

makeopencore() {
	    
	if [ "$opencore" == "custom" ] ; then 
		makeopencorecustom
		else
		makeopencorestock
	fi

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# #  Fuction to delete and replace opencore from macinabox container # #  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  # # # # # 


replaceopencore() {

#if container set to replace opencore will delete vms opencore and replace with fresh opencore  then exit
opencorelocation="$DOMAIN"	
	
	if [ "$replaceopencore" == "yes" ] ; then
		echo "deleting existing opencore"
		rm "$DOMAIN"/"$NAME"-opencore.img
		makeopencore
		echo ""
		echo ""
		echo "Macinabox set to only replace Opencore. Nothing else done."
		echo "To install a macOS vm re-run container, change 'replace opencore' to no in the template"
		exit 
	
	else
				
		echo "continuing"
			   
	fi		

}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Try to directly inject macinabox helper userscript     # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
fixxml() {
    
	rsync -a --no-o /Macinabox/tools/fixxml/ /config/ # copy macinabox helper data to macinabox appdata
	
if [ "$injectfixxml" == "yes" ] && [ ! -e /userscripts/1_macinabox_helper ]; then
		echo "Trying to add userscript"

		unzip -d /userscripts/ /config/1_macinabox_helper.zip #extract macinabox helper userscript into userscript location
		unzip -d /userscripts/ /config/1_macinabox_vmready_notify.zip #extract macinabox notify userscript into userscript location
		rm /config/1_macinabox_helper.zip #cleanup delete zip file
		rm /config/1_macinabox_vmready_notify.zip #cleanup delete zip file
		chmod -R 777 "/userscripts/1_macinabox_helper/" && chmod 777 /config/macinabox_helper_userscript.sh #reset permissions on user script
		chmod -R 777 "/userscripts/1_macinabox_vmready_notify/" && chmod 777 /config/macinabox_vmready_notify.sh #reset permissions on user script
		echo "Injected macinabox helper and notify userscript into user script plugins and a copy of macinabox helper and notify script has been put in appdata"			
else
	# leave userscript in macinabox appdata & delete zip file
	rm /config/1_macinabox_helper.zip #cleanup delete zip file
	rm /config/1_macinabox_vmready_notify.zip #cleanup delete zip file
	chmod 777 /config/macinabox_helper_userscript.sh #reset permissions on user script
	chmod 777 /config/macinabox_vmready_notify.sh #reset permissions on user script
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

if [ "$overridenic" == "virtio" ] ; then
	nictype="virtio"
elif [ "$overridenic" == "e1000-82545em" ] ; then
		nictype="e1000-82545em"
elif [ "$overridenic" == "virtio-net" ] ; then
			nictype="virtio-net"
elif [ "$overridenic" == "vmxnet3" ] ; then
				nictype="vmxnet3"	
	else
		echo "Going with the default nic type for the macOS vm"
	fi

if [ ! -e /config/autoinstall/"$XML".xml ] ; then
	sed "s?XXXX?$VMIMAGES?" </Macinabox/xml/"$XML".xml > /tmp/tempxml.xml
	sed "s?YYYY?$ISOIMAGES?" </tmp/tempxml.xml > /tmp/tempxml2.xml
	sed "s?ZZZZ?$vdisktype?" </tmp/tempxml2.xml > /tmp/tempxml3.xml
	sed "s?WWWW?$nictype?" </tmp/tempxml3.xml > /config/autoinstall/"$XML".xml
	
	chmod 777 /config/autoinstall/"$XML".xml
	rm /tmp/tempxml.xml && rm /tmp/tempxml2.xml && rm /tmp/tempxml3.xml
	echo "macOS VM template generated and moved to server (You need to run macinabox_helper userscript)"
	echo "."
	echo "."
	rsync -a --no-o /config/autoinstall/"$XML".xml /config/"$XML"_original.xml #put an original backup of xml file in macinabox appdata

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
    "/Macinabox/tools/FetchMacOS/fetch-macOS-v2.py" -s high-sierra || exit 1;
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
         "/Macinabox/tools/FetchMacOS/fetch-macOS-v2.py" -s mojave || exit 1;
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
	    "/Macinabox/tools/FetchMacOS/fetch-macOS-v2.py" -s catalina || exit 1;
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
	    "/Macinabox/tools/FetchMacOS/fetch-macOS-v2.py" -s big-sur || exit 1;
		
	else
		echo "Media already exists. I have already downloaded the Big Sur install media before"
	    echo "."
	    echo "."

	fi
	
	}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  Pull Monterey if not already downloaded    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 	
	
		pullmonterey() {

			if [ ! -e /isos/Monterey-install.img ] ; then
				echo "I am going to download the Monterey recovery media. Please be patient!"
			    echo "."
			    echo "."
		    python3 "/Macinabox/tools/FetchMacOS/fetch-macOS-v2.py" -s monterey || exit 1;
		
		else
			echo "Media already exists. I have already downloaded the Monterey install media before"
		    echo "."
		    echo "."

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
	echo "A  Vdisk of $vdisksize was created in $DOMAIN "
fi
    echo "."
    echo "."
    echo "OpenCore bootloader image named $NAME-opencore.img was put in your Unraid vm share in the folder named $NAME"
    echo "."
	echo "."
    echo "Custom ovmf files are in /mnt/user/system/custom_ovmf"
	echo "."
	echo "."
	if [ "$SKIPXML" = "yes" ] ; then
		echo "An XML file was already present for Macinabox $NAME you will need to manually delete if you want me to replace this"
else
	echo "XML template file for the vm is ready for install with macinabox helper user script."
	echo "Note  This file assumes your vm share is the default location /mnt/user/domains"
	echo "If it isnt you will need to change the locations accordingly after in unraid vm manager before running vm"
fi

if [ "$injextfixxml" = "yes" ] ; then
    echo "The fix script should be in the userscripts plugin now"
	echo "But you will also find a copy of the custom xml fix script in /mnt/user/appdata/macinabox"
else
	echo "A copy of the macinabox helper user script was placed in /mnt/user/appdata/macinabox"
fi
	echo "."
	echo "."
	echo "OK process is now complete "
				
}

print_result_manualinstall() {
    echo "."	
	echo "Summary of what has been done"
    echo "."
    echo "."
    echo "MacOS install media was put in your Unraid isos share named $NAME-install.img"
	echo "OpenCore bootloader image was put in your Unraid isos share named $NAME-opencore.img"
	
if [ "$injextfixxml" = "yes" ] ; then
    echo "The macinabox helper script should be in the userscripts plugin now"
	echo "But you will also find a copy of the macinabox helper script in /mnt/user/appdata/macinabox"
else
	echo "The macinabox helper script was placed in /mnt/user/appdata/macinabox"
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


mkdir -vp /config/baseimage_temp
		
if [ "$flavour" == "Catalina" ] ; then
	XML="Macinabox Catalina"
	nictype="e1000-82545em"
	NAME="Catalina"
	DOMAIN=/domains/"$XML"
	replaceopencore
	pullcatalina
	automanual
elif [ "$flavour" == "Big Sur" ] ; then	
    XML="Macinabox BigSur"
	nictype="virtio"
	NAME="BigSur"
	DOMAIN=/domains/"$XML"
	replaceopencore
	pullbigsur
    automanual
elif [ "$flavour" == "Mojave" ] ; then
	XML="Macinabox Mojave"
	nictype="e1000-82545em"
	NAME="Mojave"
	DOMAIN=/domains/"$XML"
	replaceopencore
	pullmojave
	automanual
elif [ "$flavour" == "High Sierra" ] ; then
	XML="Macinabox HighSierra"
	nictype="e1000-82545em"
	NAME="HighSierra"
	DOMAIN=/domains/"$XML"
	replaceopencore
	pullhsierra
	automanual	
elif [ "$flavour" == "Monterey" ] ; then
	XML="Macinabox Monterey"
	nictype="virtio"
	NAME="Monterey"
	DOMAIN=/domains/"$XML"
	replaceopencore
	pullmonterey
	automanual				
else
	echo "I dont know what OS to try and download? Is your template correct?"

fi
exit
			

