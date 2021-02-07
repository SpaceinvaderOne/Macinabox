#!/bin/bash
# fetch method selects which method to get osx with
set +x;
SCRIPTDIR="$(dirname "$0")";
cd "$SCRIPTDIR" || exit

# Method 1
# Big Sur uses script 2 for method 1
if [ "$method" = "method 1" ] && [ "$flavour" == "Big Sur" ] ; then		
# python3 fetch-macos2.py
python3 fetch-macos.py "$@" # temporary use other big sur download method for now
# others uses script 1 for method 1
elif [ "$method" = "method 1" ] ; then
python3 fetch-macos.py "$@"
fi

# Method 2
# Big Sur uses script 1 for method 2
if [ "$method" = "method 2" ] && [ "$flavour" == "Big Sur" ] ; then	
python3 fetch-macos.py "$@"	
# others uses script 2 for method 2
elif [ "$method" = "method 2" ] ; then
python3 fetch-macos2.py
fi

exit;
