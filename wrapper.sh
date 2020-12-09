#!/bin/bash
# wrapper script to stop script running twice from startapp.sh

#check if  set to use macinabox  and run before file doesnt exist
if [ "$onlyvirt" == "macinabox_with_virtmanager" ] && [ ! -e /tmp/runbefore ]; then

# make file in tmp directory to show macinabox has run already since container has started
    touch /tmp/runbefore # put a file in ram to see if script run before since container started
	nohup /Macinabox/unraid.sh > /config2/macinabox_"$flavour".log &
	
	else
# make script exit if template was set to virtmanager only and run virtmanger	
	exit
	fi