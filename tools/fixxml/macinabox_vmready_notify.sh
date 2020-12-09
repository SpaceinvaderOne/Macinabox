#!/bin/bash
# script to notify on Unraid server when Macinabox has finished downloading install media 
# by SpaceinvaderOne

while [ ! -d /mnt/user/appdata/macinabox/autoinstall/ ]
do
  sleep 5 #wait 5 seconds before rechecking
done
/usr/local/emhttp/webGui/scripts/notify -e "Unraid Server Notice" -s "Macinabox" -d "macOS now ready to install (now run helper script)" -i "normal"
exit








