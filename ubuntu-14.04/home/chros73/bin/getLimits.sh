#!/bin/bash
# Calculates uprate limit for slowup throttle or global downrate limit based on the parameters or gives info about them.
# Usage: getLimits.sh action global_upload_rate throttle_upload_rate [throttle_upload_limit]
#   action can be: up | down | info
# 1. Getting new uprate limit for slowup throttle
#   You have to specify the top of the cap (sluplimit : highest allowable value in KiB, e.g. 1700)
#     and the bottom of the cap (sldownlimit : lowest allowable value in KiB, e.g. 100) for slowup throttle.
#   Dynamically adjusts the 2nd group (slowup throttle) uprate (upload speed) to always leave enough bandwidth to the 1st main group.
#     It works like this: checks the current throttle uprate and main uprate (with the help of the global uprate), then it raises or
#       lowers the throttle limit according to the uprate of the main group.
#     You should leave a considerable amount of gap (20% (~ 500 KiB)) between the top of the cap (sluplimit , e.g. 1700) and the
#       max global upload rate (upload_rate : the global upload limit , e.g. 2200) to be able to work efficiently (to leave bandwidth
#       to the main group between checks (within that 20 seconds interval)).
# 2. Getting new global downrate limit
#   You have to specify the top of the cap (gldownlimitmax in KB, e.g. 9999) and the bottom of the cap (gldownlimitmin in KB, e.g. 7500)
#     and global uprate limit (alluplimit in KB, e.g. 1600) and main uprate limit (mainuplimit in KB, e.g. 1200).
#   Dynamically adjusts the global download rate limit to be able to max out the full upload bandwidth. It's good for async connection
#     (e.g. ADSL) where upload speed can be slowed down if download speed is close to max. It results either max or min setting whether
#     global upload rate is bigger than the specified global uprate limit (alluplimit) and main upload rate is bigger than the specified
#     main uprate limit (mainuplimit).

###### Edit ######
### Variables for getting upload rate limit for slowup throttle
# Max value of uprate limit for slowup throttle in KB
sluplimit=1700;
# Min value of uprate limit for slowup throttle in KB
sldownlimit=100;

### Variables for getting global downrate limit
# Maximum value of global download rate in KB
gldownlimitmax=9999;
# Minimum value of global download rate in KB
gldownlimitmin=7500;
# Global upload rate limit in KB
alluplimit=1600;
# Main upload rate limit in KB
mainuplimit=1200;
###### Edit ######


action=$1
allup=${2%.*};
slowup=${3%.*};
maxslowup=${4%.*};


# Function: get mainup speed
getMainUp () {
    let local mainup=${allup// /}-${slowup// /};
    if [ "$mainup" -lt 0 ]; then
	mainup=0;
    fi;
    echo -e $mainup
}


# Function: get up speed limit for slowup throttle group
up () {
    let local newslowup=${sluplimit// /}-${mainup// /};
    if [ "$newslowup" -gt "$sluplimit" ]; then
	echo -n $sluplimit;
    elif [ "$newslowup" -gt "$sldownlimit" ]; then
	echo -n $newslowup;
    else
	echo -n $sldownlimit;
    fi
}


# Function: get global down speed limit
down () {
    if [ "$allup" -gt "$alluplimit" ] && [ "$mainup" -gt "$mainuplimit" ] ; then
	echo -n $gldownlimitmin;
    else
	echo -n $gldownlimitmax;
    fi;
}


# Function: get info about speed and limits
info () {
    echo -n "MainUpRate: $mainup , ThrottleUpRate: $slowup , ThrottleLimit: $maxslowup"
}



# Main script: checks parameters and fires up one of the actions
if [ ! $# -ge 3 ] && ([ ! "$action" == "up" ] || [ ! "$action" == "down" ] || [ ! "$action" == "info" ]); then
    echo -n "";
    exit 0;
else
    mainup=$(getMainUp)
    $1
fi;


