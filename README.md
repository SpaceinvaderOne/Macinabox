## **Macinabox**

This is a container to be run on an Unraid server. It will help with the setup of a MacOS VM.
To use this please install through Unraid's community applications but you can see the template here https://raw.githubusercontent.com/SpaceinvaderOne/Docker-Templates-Unraid/master/spaceinvaderone/macinabox.xml


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
