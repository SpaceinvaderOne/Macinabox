#!/bin/bash

start() {
    if [ -f /config/delete_me_to_reset_v4.txt ]; then
        chmod -R 777 /config/
        cd /config/run
        ./unraid.sh  
    else
        rm -f /config/*.xml
        rm -f /config/*.txt
        rm -f /config/macinabox.png
        rm -rf /config/bootloader
        rm -rf /config/custom_opencore
        rm -rf /config/stock_opencore
        rm -rf /config/run
        cp -r /app/Macinabox/* /config/
        chmod -R 777 /config/
        cd /config/run
        ./unraid.sh  
    fi
}

start

sleep "$SLEEPTIME"
