## **Macinabox**

This is a container to be run on an Unraid server. It will help with the setup of a MacOS VM.
To use this please install through Unraids community applications 



> *Variables in unraid template*

flavour 

            --catalina
            --mojave
            --high-sierra

vminstall

                --full-install
                --prepare-install

TYPE
   

       qcow2
       raw

vdisksize

              64G   (or the size you want)

> *Paths in template*






    /image                                   /mnt/user/domains/
    /xml                                     /etc/libvirt/qemu/
    /config                                  /mnt/user/appdata/macinabox/
    /Macinabox/tools/FetchMacOS/BaseSystem   /mnt/user/appdata/macinabox/Basesystem
