# Macinabox
Unraid docker image to help install MacOS vms on an Unraid server.
Either Monterey, Big Sur, Catalina, Mojave or High Sierra. 
It can fully autoinstall a macOS VM on the server. Also it can prepare all files ready for a manual install if you prefer
Tools are also provided to fix the xml when the custom xml has been stripped out of the VM after its been edited by the Unraid VM manager.

Also needed are
You need to have the "User Scripts" plugin installed from Unraid Community applications
Optional for the correct icons for macOS, please install  "vm_custom_icons" container from Unraid Community applications
 
Usage
## Operating System Version:  
                Choose version from below
				Big Sur (default)
				Monterey
				Catalina
 				Mojave
 				High Sierra
				
 VM Images Location:      Location of your vm share ( default /mnt/user/domains/ )

 Install Type: 		
                Auto install  # (This will download MacOS and install needed files into your VM location.)
 
            	Manual- install # (This will download MacOS and put all needed files into correct place ready for easy manual install.)
 
## Vdisk size :   The size you want your vdisk to be created

## Vdisk type:    Set vdisk type raw or qcow2

## Opencore stock or custom:   Select the defualt Opencore in Macinabox or use one added in macinabox appdata in the folder custom_opencore

## Delete and replace Opencore:  Select No or Yes to delete your vms opencore image and replace with fresh one.

## Override defualt NIC type:  Default No -  Override the default nic type in the vm going to be installed.

## VM Images Location:  You only need to change if your VM images are not in the default location /mnt/user/domains

## VM Images Location AGAIN:  Only needs changing if you changed the above. Location must match the above.

## sos Share Location: You only need to change if your ISO images are not in the default location /mnt/user/isos
				 
## Isos Share Location:  This is where macinabox will put install media and Opencore bootloader
                  
## appdata location:     If you change this you will need to do the same in the macinabox help user script
