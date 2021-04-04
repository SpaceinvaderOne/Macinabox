#!/bin/bash
# fetch method selects which method to get osx with
set +x;
SCRIPTDIR="$(dirname "$0")";
cd "$SCRIPTDIR" || exit

# Method 1 or 2
if [ "$method" = "method 1" ] ; then		
# method 1 uses script2
python3 fetch-macos2.py 
# method 2 uses script 1 
elif [ "$method" = "method 2" ] ; then
python3 fetch-macos.py "$@"
fi


exit;
