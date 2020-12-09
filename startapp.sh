#!/bin/sh

	
#if set to use macinabox_with_virtmanager macinabox and virtmanager will be run 
if [ $onlyvirt == "macinabox_with_virtmanager" ]; then
# if set to both then run macinabox then virt manager
exec /Macinabox/wrapper.sh &
export HOME=/config
exec /usr/local/bin/virt-manager --no-fork 
	else
		
# if set to virtmanager only vitmanager is run
export HOME=/config
exec /usr/local/bin/virt-manager --no-fork 
	fi


