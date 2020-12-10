#!/bin/bash
# script to add back custom xml to a macos vm and/or install vm on autoinstall macinabox 
# by SpaceinvaderOne

# vm name (put the name of the vm as defined in your template)
NAME="put the name of the vm from template here"

# leave as "no" when you are running this script after you have sucessfully installed the OS.
#  The setting "no" will then change the network type to intel to allow apple services
#  Only set to "yes" if you have NOT completed the install process. This will set network to the needed vmxnet3 to do this.
FIRSTINSTALL="yes"

# leave set to "no" when your core count is standard
# set to "yes" if boot hangs on the apple logo due to you assigned a non standard amount of cores to the vm
REMOVETOPOLOGY="no"

# leave set to "custom" to use custom macinabox ovmf files
# set to "unraid" to use the defualt unraid ovmf files
OVMF="custom"

#########IF YOUR APPDATA SHARE IS NOT IN THE DEFAULT LOCATION THEN CHANGE BELOW)
appdata=/mnt/user/appdata/

##### Dont change anything below here #########

##### Script functions ########################

fixnetworkpreinstall() {	
# look for network type and change  type to vmxnet3 to allow macOS to be able to install
if grep -q "<model type='virtio'/>" /tmp/"$XML".xml; then
	sed "s_<model type='virtio'/>_<model type='vmxnet3'/>_" </tmp/"$XML".xml >/tmp/"$XML"2.xml
	echo "Changed network type from virtio to vmxnet3."
	NETWORK="vmxnet3"
	DEFINEVM="yes"
elif grep -q "<model type='virtio-net'/>" /tmp/"$XML".xml; then
	sed "s_<model type='virtio-net'/>_<model type='vmxnet3'/>_" </tmp/"$XML".xml >/tmp/"$XML"2.xml
	echo "Changed network type from virtio to vmxnet3."
	NETWORK="vmxnet3"
	DEFINEVM="yes"
elif grep -q "<model type='e1000-82545em'/>" /tmp/"$XML".xml; then
	sed "s_<model type='virtio-net'/>_<model type='vmxnet3'/>_" </tmp/"$XML".xml >/tmp/"$XML"2.xml
	echo "Changed network type from e1000-82545em to vmxnet3."
	NETWORK="vmxnet3"
	DEFINEVM="yes"
else
	echo "No network adapters in xml to change. Network adapter is already vmxnet3"
	cp /tmp/"$XML".xml /tmp/"$XML"2.xml
	NETWORK="skip"
fi
}


fixnetworkpostinstall() {
# look for network type and change to correct type for macOS e1000-82545em
if grep -q "<model type='virtio'/>" /tmp/"$XML".xml; then
	sed "s_<model type='virtio'/>_<model type='e1000-82545em'/>_" </tmp/"$XML".xml >/tmp/"$XML"2.xml
	echo "Changed network type from virtio to intel e1000-82545em"
	NETWORK="e1000-82545em"
	DEFINEVM="yes"

elif grep -q "<model type='virtio-net'/>" /tmp/"$XML".xml; then
	sed "s_<model type='virtio-net'/>_<model type='e1000-82545em'/>_" </tmp/"$XML".xml >/tmp/"$XML"2.xml
	echo "Changed network type from virtio-net to intel e1000-82545em"
	NETWORK="e1000-82545em"
	DEFINEVM="yes"

# swap vmxnet3 after install. (vmxnet3 is only used for install of macOS after e1000 is needed to be able to use Apple services)
elif grep -q "<model type='vmxnet3'/>" /tmp/"$XML".xml; then 
	sed "s_<model type='vmxnet3'/>_<model type='e1000-82545em'/>_" </tmp/"$XML".xml >/tmp/"$XML"2.xml
	echo "Changed network type from vmxnet3 to intel e1000-82545em"
	NETWORK="e1000-82545em"
	DEFINEVM="yes"
else	
	echo "No network adapters in xml to change.. Network adapter is already e1000-82545em"
	cp /tmp/"$XML".xml /tmp/"$XML"2.xml
	NETWORK="skip"
	
fi
}


addcustom() {

if grep -q "<qemu:commandline>" /tmp/"$XML".xml; then #if qemu:args are present dont add them
	echo "The qemu:args look like they are already set so i will not add them"
	cp /tmp/"$XML"2.xml /tmp/"$XML"4.xml
	CUSTOMXML="no"
else 
# add addition qemu args for macOS
sed "s_<domain type='kvm'>_<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>_" </tmp/"$XML"2.xml >/tmp/"$XML"3.xml
sed 's_</domain>_ <qemu:commandline>_' </tmp/"$XML"3.xml >/tmp/"$XML"4.xml
echo "<qemu:arg value='-usb'/>" | tee --append /tmp/"$XML"4.xml
echo "<qemu:arg value='-device'/>" | tee --append /tmp/"$XML"4.xml
echo "<qemu:arg value='usb-kbd,bus=usb-bus.0'/>" | tee --append /tmp/"$XML"4.xml
echo "<qemu:arg value='-device'/>" | tee --append /tmp/"$XML"4.xml
echo "<qemu:arg value='isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc'/>" | tee --append /tmp/"$XML"4.xml
echo "<qemu:arg value='-smbios'/>" | tee --append /tmp/"$XML"4.xml
echo "<qemu:arg value='type=2'/>" | tee --append /tmp/"$XML"4.xml
echo "<qemu:arg value='-cpu'/>" | tee --append /tmp/"$XML"4.xml
echo "<qemu:arg value='Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,+pcid,+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check'/>" | tee --append /tmp/"$XML"4.xml
echo "</qemu:commandline>" | tee --append /tmp/"$XML"4.xml
echo "</domain>" | tee --append /tmp/"$XML"4.xml
echo "Added custom qemu:args for macOS"
CUSTOMXML="yes"
DEFINEVM="yes"
fi
}


topology() {
# remove topoly line in xml to fix sticking on apple logo during boot with non standard core configs
if [ "$REMOVETOPOLOGY" = "yes" ] ; then
	sed '/<topology/d' </tmp/"$XML"4.xml >/tmp/"$XML"5.xml
	sed '/<cache mode/d' </tmp/"$XML"5.xml >/tmp/"$XML"6.xml
	sed '/<feature policy/d' </tmp/"$XML"6.xml >/tmp/"$XML"7.xml
	echo "topolgy line removed"
	FIXTOPOLOGY="yes"
	DEFINEVM="yes"
elif [ "$REMOVETOPOLOGY" = "no" ] ; then
	cp /tmp/"$XML"4.xml /tmp/"$XML"7.xml	
	echo "topolgy line left as is"
	FIXTOPOLOGY="no"
else 
echo "REMOVETOPOLOGY VARIABLE NOT SET CORRECTLY USE YES OR NO"
	exit 1
fi
}

customovmf() {
# remove topoly line in xml to fix sticking on apple logo during boot with non standard core configs
if [ "$OVMF" = "custom" ] ; then
    sed "s?/usr/share/qemu/ovmf-x64/OVMF_CODE-pure-efi.fd?/mnt/user/system/custom_ovmf/Macinabox_CODE-pure-efi.fd?" </tmp/"$XML"7.xml >/tmp/"$XML"fixed.xml
	echo "custom ovmf added"
	CUSTOM="yes"
	DEFINEVM="yes"
elif [ "$OVMF" = "unraid" ] ; then
	cp /tmp/"$XML"7.xml /tmp/"$XML"fixed.xml	
	echo "topolgy line left as is"
	CUSTOM="no"
else 
echo "OVMF VARIABLE NOT SET CORRECTLY USE custom OR unraid"
	exit 1
fi
}

installvm() {
# Install new VM into Unraid if autoinstall was selected in macinabox template
if [ ! -d $appdata"macinabox/autoinstall/" ]; then
# Print message and continue on to fix xml
echo "Starting to Fix XML"	
else
virsh define $appdata"macinabox/autoinstall/Macinabox*.xml"
echo "VM is now installed. Goto VM tab to run"
echo "Rerun this script if you make any changes to the macOS VM using the Unraid VM manger"
#cleanup then exit script
rm -r $appdata"macinabox/autoinstall"
exit
fi
}

define() {
if [ "$DEFINEVM" = "yes" ] ; then
# define vm from fixed xml then cleanup temp files
virsh define /tmp/"$XML"fixed.xml && rm /tmp/"$XML"*.xml
results

else 
echo ""
echo ""
echo "This is what has been done to the xml"
echo ""
echo "Nothing needed fixing in the XML. XML has all custom elemnents present."
echo "Nothing done."

fi
}

results() {
# print whats been done to the xml
echo "This is what has been done to the xml"
echo ""
if [ "$NETWORK" = "vmxnet3" ] ; then
echo "Network type was changed to vmxnet3."
echo "vmxnet3 should be used only during the install of macOS."
echo "If you have already completed the install process then you should set the variable FIRSTRUN to no and run this script again."

elif [ "$NETWORK" = "e1000-82545em" ] ; then
echo "Network type was changed to intel e1000-82545em"
echo "e1000-82545em is needed if you want to use any apple services in your VM."
echo "If you have NOT completed the install process then you should set the variable FIRSTRUN to yes and run this script again."

else 
echo "Your network type was already correct. Network has not been changed."
fi

if [ "$CUSTOMXML" = "yes" ] ; then
echo "The custom qemu:args have been added to you xml."
else
echo "Custom qemu:args were already present. So not added."
fi

if [ "$CUSTOM" = "yes" ] ; then
echo "VM is set to use custom ovmf files."
else
echo "VM is set to use the standard Unraid ovmf files."
fi

if [ "$FIXTOPOLOGY" = "yes" ] ; then
echo "The topology line was removed from the xml"
echo "This will now allow you to run macOS with a non standard number of core assigned to the VM"
fi

echo "xml is now fixed. Now goto your vm tab and run the VM"
echo "Rerun this script if you make any other changes to the macOS VM using the Unraid VM manger"

}

##### end of functions #############

#install new vm (if needed) if autoinstall selected in macinabox template
installvm

#export xml from macOS vm to fix
XML="$NAME"
virsh dumpxml "$NAME" > /tmp/"$XML".xml

#check if firstinstall set to yes or no then run fixnetwork type function
if [ "$FIRSTINSTALL" = "yes" ] ; then
	fixnetworkpreinstall
elif [ "$FIRSTINSTALL" = "no" ] ; then	
	fixnetworkpostinstall
else 
	echo "FIRSTINSTALL VARIABLE NOT SET CORRECTLY"
	exit 1
fi

#run addcustom (qemu:args) function
addcustom

#run topology fuction
topology

#run custom ovmf fuction
customovmf

#run define vm from fixed xml function
define

exit















