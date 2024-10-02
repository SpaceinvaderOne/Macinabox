#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #  unraid.sh - Script used by Macinabox docker conatainer to install a KVM virtual machine of different versions of macOS # # 
# #  by - SpaceinvaderOne                                                                                                   # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#  get the host path for a given container path using Docker inspect # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


function get_host_path {
    local container_path="$1"
    local container_id=$(hostname)

    # get container details using Docker api
    local container_details=$(curl -s --unix-socket /var/run/docker.sock http://localhost/containers/$container_id/json)

    # parse the  details & extract the corresponding host path
    local host_path=$(echo "$container_details" | jq -r --arg container_path "$container_path" '.Mounts[] | select(.Destination == $container_path) | .Source')

    # see if the host path was found
    if [ -z "$host_path" ]; then
        echo "No bind mount found for container path: $container_path"
        return 1
    else
        echo "$host_path"
    fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Function to see the highest available qemu types on server # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


get_highest_machine_types() {
    # q35 chipset - run using chroot and set variable
    highest_q35=$(chroot /host /usr/bin/qemu-system-x86_64 -M help | grep -o 'pc-q35-[0-9]\+\.[0-9]\+' | sort -V | tail -n 1)

    # i440fx chipset - run using chroot and set variable
    highest_i440fx=$(chroot /host /usr/bin/qemu-system-x86_64 -M help | grep -o 'pc-i440fx-[0-9]\+\.[0-9]\+' | sort -V | tail -n 1)

   # echo "Highest Q35 machine type available: $highest_q35"
   #  echo "Highest i440fx machine type available: $highest_i440fx"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Function to get the vm default vm network source # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


get_vm_network() {

    CONFIG_FILE="/vm/domain.cfg"

    # see if the file exists
    if [[ -f "$CONFIG_FILE" ]]; then
        # Read the BRNAME value from the file
        BRNAME=$(grep -oP '^BRNAME="\K[^"]+' "$CONFIG_FILE")

        # see if the BRNAME variable is not empty
        if [[ -n "$BRNAME" ]]; then
            # echo "Vm default network source type is set to \"$BRNAME\""
            :
        else
            echo "Vm default network source type is not set."
        fi
    else
        echo "Cant see the config file on server at /boot/config/domain.cfg"
    fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Override default name if one is set  for the vm  # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


check_and_set_name() {
    ISONAME="$NAME"
    # see if CUSTOMNAME is blank or set to any variation of "default"
    if [ -z "$CUSTOMNAME" ] || [[ "$CUSTOMNAME" =~ ^(default|Default|DEFAULT)$ ]]; then
        echo "CUSTOMNAME is either blank or set to 'default'. Continuing without changes."
    else
        # if CUSTOMNAME is not blank and not any variation of "default", set NAME to CUSTOMNAME
        NAME="$CUSTOMNAME"
        echo "CUSTOMNAME is set to '$CUSTOMNAME'. Setting NAME to '$CUSTOMNAME'."
    fi
    check_version
    checkeula
    icon
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Auto install the vm [main funcrion]  # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


autoinstall() {

    # check there is a folder in the domains share named the version of the macOS being installed. If not create it
    if [ ! -d "$DOMAIN" ] ; then
        mkdir -vp "$DOMAIN"
        echo "I have created the Macinabox directories"
        echo "."
    else
        echo "Macinabox directories are already present......continuing."
        echo "."
    fi

    # check if a vdisk is present to install macOS on. If not create one
    if [ ! -e "$DOMAIN"/macos_disk.img ]; then
        qemu-img create -f $vdisktype "$DOMAIN"/macos_disk.img "$vdisksize"
        echo "."
        echo "Created vdisk"
        echo "."
    else
        echo "There is already a vdisk image here...skipping"
        echo "."
        SKIPVDISK=yes
    fi

    chmod -R 777 "$DOMAIN"/ # reset permissions
    makeimg # convert dmg and put in iso share
    makeopencore # extract and move Opencore to isos share
    addxml
    definevm
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Converts the downloaded macOS Baseimage as dmg to a usable  img format # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


makeimg() {
# check if install image has previously been created and if not convert baseimage and put in iso share
if [ ! -e /isos/"$ISONAME"-install.img ] ; then
qemu-img convert "/config/run/BaseSystem.dmg" -O raw "/isos/$ISONAME-install.img"
touch /config/install_media_is_in_isos_share # make a file showing user where install media is located
chmod 777 "/isos/$ISONAME-install.img"
#cleanup - remove baseimage from macinabox appdata now its been converted and moved
rm /config/run/BaseSystem.dmg
rm /config/run/BaseSystem.chunklist
else
SKIPIMG=yes
fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Fuction to delete and replace opencore if wanted leaving install as is # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

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
				
		echo "Starting install"
			   
	fi		

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Use stock or custom opencore   # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

makeopencore() {
    # make the directories if not there
    mkdir -vp /config/custom_opencore && cp /app/readmecustomopencore.txt /config/custom_opencore/readme.txt
    mkdir -vp /config/stock_opencore

    # see if OpenCore image already exists
    if [ ! -e "$DOMAIN"/"$NAME"-opencore.img ]; then
        #  custom OpenCore logic
        file=$(ls /config/custom_opencore/*.iso.gz 2>/dev/null)

        if [ -n "$file" ]; then
            echo "Extracting custom OpenCore from $file"
            if gunzip -dk "$file"; then
                iso_file="${file%.gz}"
                if [ -e "$iso_file" ]; then
                    echo "Moving custom OpenCore to the VM share"
                    if rsync -a --no-o "$iso_file" "$DOMAIN"/"$NAME"-opencore.img; then
                        chmod 644 "$DOMAIN"/"$NAME"-opencore.img 
                        rm "$iso_file" # Cleanup extracted ISO
                    else
                        echo "Failed to move custom OpenCore image"
                        exit 1
                    fi
                else
                    echo "Expected .iso file not found after extraction $iso_file"
                    exit 1
                fi
            else
                echo "Failed to extract $file"
                exit 1
            fi
        else
            # if no custom OpenCore, use stock from container
            echo "No custom OpenCore .iso.gz file found, using stock version"

            # location of stock in container
            file=$(ls /config/bootloader/OpenCore*.iso.gz 2>/dev/null)

            if [ -n "$file" ]; then
                echo "Extracting stock OpenCore from $file"
                if gunzip -dk "$file" -c > /config/stock_opencore/OpenCore.iso; then
                    iso_file="/config/stock_opencore/OpenCore.iso"
                    if [ -e "$iso_file" ]; then
                        echo "Moving stock OpenCore to the VM share"
                        if rsync -a --no-o "$iso_file" "$DOMAIN"/"$NAME"-opencore.img; then
                            chmod 644 "$DOMAIN"/"$NAME"-opencore.img 
                            touch /config/opencore_is_in_vms_share # set a file to say where OpenCore is located
                            rm "$iso_file" # cleanup extracted stock OpenCore
                        else
                            echo "Failed to move stock OpenCore image"
                            exit 1
                        fi
                    else
                        echo "Expected .iso file not found after extraction: $iso_file"
                        exit 1
                    fi
                else
                    echo "Failed to extract $file"
                    exit 1
                fi
            else
                echo "No stock OpenCore .iso.gz file found"
                exit 1
            fi
        fi
    else
        echo "$NAME-opencore.img already exists. To replace it, set 'replaceopencore' to yes in the template."
    fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# ADD THE VM TEMPLATE USED TO DEFINE THE VM    # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


addxml() {

    # preparation
    
    cp "/config/macinabox.xml" "/config/macinabox_tmp.xml"
    XML_FILE="/config/macinabox_tmp.xml"
    XML_FILE2="/config/$NAME.xml"  
    UUID=$(uuidgen)
    nvram_file="/etc/libvirt/qemu/nvram/${UUID}_VARS-pure-efi.fd"
    MAC=$(printf 'AC:87:A3:%02X:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))  # random mac address with apple prefix
	

# create custom xml from the standard template

# add vm name to xml
sed -i "s#<name>.*</name>#<name>$NAME</name>#" "$XML_FILE"

# replace uuid with newly generated one
sed -i "s#<uuid>.*</uuid>#<uuid>$UUID</uuid>#" "$XML_FILE"

# set vm to have the highest q35 on server
sed -i "s#<type arch='x86_64' machine='XXXXXX'>#<type arch='x86_64' machine='$highest_q35'>#" "$XML_FILE"

# replace hte nvram with created nvram file
sed -i "s#<nvram>.*</nvram>#<nvram>$nvram_file</nvram>#" "$XML_FILE"

# add loacation for opencore image
sed -i "s#<source file='Macinabox-opencore.img'/>#<source file='$DOMAINS_SHARE/$NAME/$NAME-opencore.img'/>#" "$XML_FILE"

# add location for install image
sed -i "s#<source file='Macinabox-install.img'/>#<source file='$ISOS_SHARE/$ISONAME-install.img'/>#" "$XML_FILE"

# add the driver type
sed -i "s#driver name='qemu' type='XXXXXX' cache='writeback'/>#driver name='qemu' type='$vdisktype' cache='writeback'/>#" "$XML_FILE"

# add location for main vdisk
sed -i "s#<source file='Macinabox-macos_disk.img'/>#<source file='$DOMAINS_SHARE/$NAME/macos_disk.img'/>#" "$XML_FILE"

# set the MAC address
sed -i "s#<mac address='.*'/>#<mac address='$MAC'/>#" "$XML_FILE"

# set the bridge name with the value of $BRNAME
sed -i "s#<source bridge='XXX'/>#<source bridge='$BRNAME'/>#" "$XML_FILE"

# set the NIC model type for the vm
sed -i "s#<model type='XXXXXXX'/>#<model type='$overridenic'/>#" "$XML_FILE"

# set the specific qemu argument with the value of $CPUARGS from the template
sed -i "s#<qemu:arg value='XXXXXX'/>#<qemu:arg value='$CPUARGS'/>#" "$XML_FILE"

# check for vhostX network source and change network block to suit
if [[ $BRNAME =~ ^vhost[0-9]+$ ]]; then
    sed -i "s#<interface type='bridge'>#<interface type='direct' trustGuestRxFilters='yes'>#" "$XML_FILE"
    sed -i "s#<source bridge='.*'/>#<source dev='$BRNAME' mode='bridge'/>#" "$XML_FILE"
fi

# renmae the the temp xml
mv "$XML_FILE" "$XML_FILE2"

# create an nvram file based off generated uuid for the vm
echo "As this is an OVMF VM, I need to create an NVRAM file. Creating now ...."
qemu-img create -f raw "$nvram_file" 64k

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Fix or update the xml of existing VM if VM already present     # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

restorexml() {


    # see if the VM mac vm already exists
    if ! virsh list --all --name | grep -q "^${NAME}$"; then
        echo "VM called ${NAME} does not exist. Continuing to install it."
        return 0  
    fi
    XML_FILE="/config/macinabox_tmp.xml"
    REQUIRED_ADDRESS="<address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>"
    echo ""
    echo "Checking macOS VM named ${NAME} that its XML is correct and fixing if needed"
    echo "Nic will be set to \"$overridenic\""

    # dump the VM's xml configuration 
    virsh dumpxml "$NAME" > "$XML_FILE"

    # check the <domain> tag includes the qemu namespace
    sed -i "s_<domain type='kvm'>_<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>_" "$XML_FILE"

    # see if <qemu:commandline> exists in the XML
    if grep -q "<qemu:commandline>" "$XML_FILE"; then
        echo "Found existing <qemu:commandline>. Removing and adding new configuration."
        # delete the existing <qemu:commandline> section
        sed -i '/<qemu:commandline>/,/<\/qemu:commandline>/d' "$XML_FILE"
    else
        echo "No existing <qemu:commandline> found. Adding new configuration."
    fi

    # add the custom xml needed for macos
    sed -i "/<\/domain>/i\\
    <qemu:commandline>\\
      <qemu:arg value=\"-device\"/>\\
      <qemu:arg value=\"isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc\"/>\\
      <qemu:arg value=\"-smbios\"/>\\
      <qemu:arg value=\"type=2\"/>\\
      <qemu:arg value=\"-usb\"/>\\
      <qemu:arg value=\"-device\"/>\\
      <qemu:arg value=\"usb-tablet\"/>\\
      <qemu:arg value=\"-device\"/>\\
      <qemu:arg value=\"usb-kbd\"/>\\
      <qemu:arg value=\"-cpu\"/>\\
      <qemu:arg value=\"XXXXXX\"/>\\
    </qemu:commandline>" "$XML_FILE"

    # replace the xxxxx with the value of $CPUARGS from template
    sed -i "s#<qemu:arg value=\"XXXXXX\"/>#<qemu:arg value=\"$CPUARGS\"/>#" "$XML_FILE"

    # fix the adress line for macos to have corect network ability
    awk -v required_address="$REQUIRED_ADDRESS" '
    /<interface type=.bridge.>/ {
        in_interface = 1;
    }
    in_interface && /<model type=/ {
        in_model = 1;
    }
    in_model && /<address type=.pci./ {
        in_address = 1;
        if ($0 != required_address) {
            # Replace the existing address with the required address
            print required_address;
            next;
        }
    }
    /<\/interface>/ {
        in_interface = in_model = in_address = 0;
    }
    {print}
    ' "$XML_FILE" > "${XML_FILE}.tmp" && mv "${XML_FILE}.tmp" "$XML_FILE"

    # replace the NIC model type with the value of that in template or default
    sed -i "/<interface.*bridge/,/<\/interface>/ s#<model type='[^']*'/>#<model type='$overridenic'/>#" "$XML_FILE"

    # set the machine type with hishest q35
    sed -i "s#<type arch='x86_64' machine='[^']*'>#<type arch='x86_64' machine='$highest_q35'>#" "$XML_FILE"

    # Check if the vcpu count is a multiple of 2
    VCPU_COUNT=$(grep -oP '(?<=<vcpu placement=.static.>)[0-9]+' "$XML_FILE")
    if ! ((VCPU_COUNT > 0 && (VCPU_COUNT & (VCPU_COUNT - 1)) == 0)); then
        echo "VCPU count is not a power of 2. Removing the topology line so vm still boots."
        sed -i '/<topology .*\/>/d' "$XML_FILE"
    else
        echo "VCPU count is a power of 2. No action needed."
    fi


    # define the VM using the updated XML file
    if virsh define "$XML_FILE"; then
        # notify if VM definition is successful
        chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
            -e "Macinabox Container" \
            -s "$NAME" \
            -d "XML checked and fixed/updated successfully." \
            -i "normal"
        echo "Done -- VM redefined successfully"
        exit 0  # exit the script successfully after defining the VM
    else
        # notify if VM definition failed
        chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
            -e "Macinabox Container" \
            -s "$NAME" \
            -d "Failed to redefine the VM from the updated XML" \
            -i "warning"
        echo "Failed to redefine the VM"
        exit 1  # Exit the script with an error if could define it
    fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# WAIT FOR NEEDED FILES THEN DEFINE THE VM     # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

definevm() {
    # check supporting files are present before defining
    local xml_file="$XML_FILE2"
    local install_img="/isos/$ISONAME-install.img"
    local opencore_img="$DOMAIN/$NAME-opencore.img"

    # are all required files present
    if [[ -f "$xml_file" && -f "$install_img" && -f "$opencore_img" ]]; then
        echo "All required files are present. Attempting to define the VM..."
        
        #  define the VM
        if virsh define "$xml_file"; then
          rm "$xml_file"
            # notify about the successful VM setup
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "VM setup successfully completed. The VM is now ready to be run." \
                -i "normal"
        else
           
            echo "Failed to define the VM. There was an error during the VM definition process."

            # notify if failed to define the VM
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "VM setup failed. There was an error during the VM definition process." \
                -i "warning"

            # exit and clean up xml
            rm "$xml_file"
            exit 1
        fi
    else
        echo "Not all required files are present. Cannot define the VM."
        echo "Missing files:"
        [[ ! -f "$xml_file" ]] && echo "  - $xml_file"
        [[ ! -f "$install_img" ]] && echo "  - $install_img"
        [[ ! -f "$opencore_img" ]] && echo "  - $opencore_img"

        # notify about the missing files and exit
        chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
            -e "Macinabox Container" \
            -s "$NAME" \
            -d "Failed to setup the VM. Required files are missing." \
            -i "warning"

        exit 1
    fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Collect info and set variables # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

collect_info() {
# # get the real paths of bind mapped locations in macinabox
DOMAINS_SHARE=$(get_host_path "/domains")
ISOS_SHARE=$(get_host_path "/isos")
APPDATA_SHARE=$(get_host_path "/config")

echo "Host path for '/domains' is $DOMAINS_SHARE"
echo "Host path for '/isos' is $ISOS_SHARE"
echo "Host path for '/config' is $APPDATA_SHARE"

# find out what highest q35 available is
get_highest_machine_types
echo "Highest Q35 machine type available is $highest_q35"

# find out what vm defualt network type is
get_vm_network
echo "The default VM network type is $BRNAME"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Pull various macOS versions  # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


# #  Pull High sierra if not already downloaded   # # 

pullhsierra() {

	if [ ! -e "/isos/${ISONAME}-install.img" ] ; then
		echo "I am going to download the HighSierra recovery media. Please be patient!"
	    echo "."
	    echo "."

        # run the Python script
        echo 1 | python3 ./fetch-macOS-v2.py
        status=$?

        # check the exit status
        if [ $status -ne 0 ]; then
            # if there is an error,  send an error notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "Something went wrong downloading the media" \
                -i "warning" \
                -m "The error code is $status"
            exit 1  
        else
            #  send a success notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "The recovery media has been downloaded" \
                -i "normal" \
                -m "It has been put in /isos/$NAME-install.img. Now I will setup your VM"
        fi

else
	echo "Media already exists. I have already downloaded the High Sierra install media before"
    echo "."
    echo "."

fi
}


# #  Pull Mojave if not already downloaded      # # 

pullmojave() {

	if [ ! -e "/isos/${ISONAME}-install.img" ] ; then
		echo "I am going to download the Mojave recovery media. Please be patient!"
	    echo "."
	    echo "."
        
		        # run the Python script
        echo 2 | python3 ./fetch-macOS-v2.py
        status=$?

        # check the exit status
        if [ $status -ne 0 ]; then
            # if there is an error,  send an error notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "Something went wrong downloading the media" \
                -i "warning" \
                -m "The error code is $status"
            exit 1  
        else
           #  send a success notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "The recovery media has been downloaded" \
                -i "normal" \
                -m "It has been put in /isos/$NAME-install.img. Now I will setup your VM"
        fi

else
	echo "Media already exists. I have already downloaded the Mojave install media before"
    echo "."
    echo "."

fi
}

	
# #  Pull Catalina if not already downloaded    # # 
	pullcatalina() {

		if [ ! -e "/isos/${ISONAME}-install.img" ] ; then
			echo "I am going to download the Catalina recovery media. Please be patient!"
		    echo "."
		    echo "."
	    
		        # run the Python script
        echo 3 | python3 ./fetch-macOS-v2.py
        status=$?

        # check the exit status
        if [ $status -ne 0 ]; then
            # if there is an error,  send an error notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "Something went wrong downloading the media" \
                -i "warning" \
                -m "The error code is $status"
            exit 1  
        else
            #  send a success notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "The recovery media has been downloaded" \
                -i "normal" \
                -m "It has been put in /isos/$NAME-install.img. Now I will setup your VM"
        fi
	else
		echo "Media already exists. I have already downloaded the Catalina install media before"
	    echo "."
	    echo "."

	fi
	}
	

# #  Pull BigSur if not already downloaded    # # 
	pullbigsur() {

		if [ ! -e "/isos/${ISONAME}-install.img" ] ; then
			echo "I am going to download the BigSur recovery media. Please be patient!"
		    echo "."
		    echo "."
	    
		        # run the Python script
        echo 4 | python3 ./fetch-macOS-v2.py
        status=$?

        # check the exit status
        if [ $status -ne 0 ]; then
            # if there is an error,  send an error notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "Something went wrong downloading the media" \
                -i "warning" \
                -m "The error code is $status"
            exit 1  
        else
            #  send a success notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "The recovery media has been downloaded" \
                -i "normal" \
                -m "It has been put in /isos/$NAME-install.img. Now I will setup your VM"
        fi
		
	else
		echo "Media already exists. I have already downloaded the Big Sur install media before"
	    echo "."
	    echo "."

	fi
	
	}


# #  Pull Monterey if not already downloaded    # # 
	
		pullmonterey() {

			if [ ! -e "/isos/${ISONAME}-install.img" ] ; then
				echo "I am going to download the Monterey recovery media. Please be patient!"
			    echo "."
			    echo "."
		  
		          # run the Python script
        echo 5 | python3 ./fetch-macOS-v2.py
        status=$?

        # check the exit status
        if [ $status -ne 0 ]; then
            # if there is an error,  send an error notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "Something went wrong downloading the media" \
                -i "warning" \
                -m "The error code is $status"
            exit 1  
        else
            #  send a success notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "The recovery media has been downloaded" \
                -i "normal" \
                -m "It has been put in /isos/$NAME-install.img. Now I will setup your VM"
        fi
		
		else
			echo "Media already exists. I have already downloaded the Monterey install media before"
		    echo "."
		    echo "."

		fi
	
		}
		

# #  Pull Ventura if not already downloaded    # # 
	
		pullventura() {

			if [ ! -e "/isos/${ISONAME}-install.img" ] ; then
				echo "I am going to download the Ventura recovery media. Please be patient!"
			    echo "."
			    echo "."
		   
		           # run the Python script
        echo 6 | python3 ./fetch-macOS-v2.py
        status=$?

       # check the exit status
        if [ $status -ne 0 ]; then
            # if there is an error,  send an error notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "Something went wrong downloading the media" \
                -i "warning" \
                -m "The error code is $status"
            exit 1  
        else
            #  send a success notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "The recovery media has been downloaded" \
                -i "normal" \
                -m "It has been put in /isos/$NAME-install.img. Now I will setup your VM"
        fi
		
		else
			echo "Media already exists. I have already downloaded the Ventura install media before"
		    echo "."
		    echo "."

		fi
	
		}
		

# #  Pull Sonoma if not already downloaded    # # 
	
		pullsonoma() {

			if [ ! -e "/isos/${ISONAME}-install.img" ] ; then
				echo "I am going to download the Sonoma recovery media. Please be patient!"
			    echo "."
			    echo "."
		    
			        # run the Python script
        echo 7 | python3 ./fetch-macOS-v2.py
        status=$?

        # check the exit status
        if [ $status -ne 0 ]; then
            # if there is an error,  send an error notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "Something went wrong downloading the media" \
                -i "warning" \
                -m "The error code is $status"
            exit 1  
        else
            #  send a success notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "$NAME" \
                -d "The recovery media has been downloaded" \
                -i "normal" \
                -m "It has been put in /isos/$NAME-install.img. Now I will setup your VM"
        fi
		
		else
			echo "Media already exists. I have already downloaded the Sonoma install media before"
		    echo "."
		    echo "."

		fi
	
		}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

checkeula() {
    if [ "$OKTORUN" = "NO" ]; then
        echo "You have indicated that you are not compliant with Apple’s EULA. Running a macOS VM on non-Apple hardware violates the EULA. If your server is running on Apple hardware, such as a Mac Pro, please update the compliance variable to 'YES'. If you do not have Apple hardware and still wish to run a macOS VM, consider purchasing a used Mac Pro ('trash can' model) from eBay for a few hundred dollars. This can serve as a Linux server, allowing you to run a macOS VM without violating the EULA. However, setting this variable to 'YES' without Apple hardware will result in a breach of the EULA. You have been warned."

        # notify if eula not compliant
        chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
            -e "Macinabox Container" \
            -s "$NAME" \
            -d "Non-compliance with Apple’s EULA detected. Exiting." \
            -i "warning" \
            -m "This server is not compliant with Apple’s EULA. If this server is Apple hardware, set the variable to 'YES' and try again."

        # exit the script
        exit 1
    else
        echo "You have stated that you are compliant with Apple’s EULA. Continuing..."
    fi
}
								
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

icon() {
    ICON_SOURCE="/config/macinabox.png"
    ICON_DESTINATION="/icons/macinabox.png"

    # does default icon exist?
    if [ ! -f "$ICON_DESTINATION" ]; then
        echo "Putting default mac vm icon in place"
        
        # copy the icon 
        cp "$ICON_SOURCE" "$ICON_DESTINATION"

        # check if the copy was successful
        if [ $? -eq 0 ]; then
            echo "Icon copied successfully."
        else
            echo "Failed to copy the icon."
        fi
    else
        echo "Icon already there skipping....."
    fi  
}  

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# used to check if container needs a new docker template    # 

check_version() {
    # check if WHATVERSION exists and equals 4
    if [[ "${WHATVERSION}" == "4" ]]; then
        echo "Version check passed. Continuing..."
    else
        echo "The version you are using is Macinbox version 4, but your Docker template doesn't match this version."
        echo "Clearing old macinabox appdata files"
        rm -rf /config/autoinstall
        rm -rf /config/baseimage_temp
        find /config -type f -name "*.xml" ! -name "macinabox.xml" -exec rm {} \;
        find /config -type f -name "*.sh" ! -path "/config/run/unraid.sh" -exec rm {} \;
        rm -f /config/.DS_Store
        echo ""
        echo "You must remove the Docker template, then reinstall the container."
        echo
        echo "To do this, goto the Docker tab, click 'macinabox' then click 'Remove'. This removes the container."
        echo "Now with the container removed, you can remove the template."
        echo ""
        echo "Next, click on the 'Apps' tab. On the left, click 'Previous Apps' and look for 'macinabox'."
        echo "Click 'Actions', then 'Remove from Previous Apps'."
        echo "Now you can search for 'macinabox' and reinstall it."
        echo "It will install with the most up-to-date template."
        echo ""

        echo "Exiting in 20 seconds..."

          #  send a notification
            chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
                -e "Macinabox Container" \
                -s "The Template for Macinbox needs updating" \
                -d "View the container logs to show you how" \
                -i "warning" \
               

        sleep 20
        exit 0 # Exiting the whole script
    fi
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# START MAIN PROCESS # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 




if [ "$flavour" == "High Sierra" ] ; then
    NAME="HighSierra"
    check_and_set_name
    collect_info
    DOMAIN=/domains/"$NAME"
    overridenic="e1000-82545em"
    restorexml
    replaceopencore
    pullhsierra
    autoinstall
elif [ "$flavour" == "Mojave" ] ; then
    NAME="Mojave"
    check_and_set_name
    collect_info
    DOMAIN=/domains/"$NAME"
    overridenic="e1000-82545em"
    restorexml
    replaceopencore
    pullmojave
    autoinstall
elif [ "$flavour" == "Catalina" ] ; then
    NAME="Catalina"
    check_and_set_name
    collect_info
    DOMAIN=/domains/"$NAME"
    overridenic="e1000-82545em"
    restorexml
    replaceopencore
    pullcatalina
    autoinstall
elif [ "$flavour" == "Big Sur" ] ; then
    NAME="BigSur"
    check_and_set_name
    collect_info
    DOMAIN=/domains/"$NAME"
    if [ "$overridenic" = "e1000-82545em" ]; then
        overridenic="virtio-net"
    fi
    restorexml
    replaceopencore
    pullbigsur
    autoinstall
elif [ "$flavour" == "Monterey" ] ; then
    NAME="Monterey"
    check_and_set_name
    collect_info
    DOMAIN=/domains/"$NAME"
    if [ "$overridenic" = "e1000-82545em" ]; then
        overridenic="virtio-net"
    fi
    restorexml
    replaceopencore
    pullmonterey
    autoinstall
elif [ "$flavour" == "Ventura" ] ; then
    NAME="Ventura"
    check_and_set_name
    collect_info
    DOMAIN=/domains/"$NAME"
    if [ "$overridenic" = "e1000-82545em" ]; then
        overridenic="virtio-net"
    fi
    restorexml
    replaceopencore
    pullventura
    autoinstall
elif [ "$flavour" == "Sonoma" ] ; then
    NAME="Sonoma"
    check_and_set_name
    collect_info
    DOMAIN=/domains/"$NAME"
    if [ "$overridenic" = "e1000-82545em" ]; then
        overridenic="virtio-net"
    fi
    restorexml
    replaceopencore
    pullsonoma
    autoinstall
else
    echo "I don't know what OS to try and download? Is your template correct?"
    chroot /host /usr/bin/php /usr/local/emhttp/webGui/scripts/notify \
        -e "Macinabox Container" \
        -s "$flavour" \
        -d "This is not supported in this container" \
        -i "warning"
fi

sleep  30
exit 0
