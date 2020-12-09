This location is to store an optional custom ovmf files for use in macinabox macOS vms.

Macinabox_CODE-pure-efi.fd is the main file. You can change/update this file to a custom file of your choosing.
Just makesure to name it "Macinabox_CODE-pure-efi.fd" as this will be the referenced in macinabox generated xml files.

The file Macinabox_VARS-pure-efi.fd is an only an NVRAM file that is used temporarily when Macinabox vm is first generated.
After the VM is run this file will no longer be used as Unraid will generate a new NVRAM file based off the VMs UUID number 
(so no need to swap or update this file) but still use the above Macinabox_CODE-pure-efi.fd.
Having Unraid generate its own NVRAM file is important so if you need to delete the VM template you can without an error.

