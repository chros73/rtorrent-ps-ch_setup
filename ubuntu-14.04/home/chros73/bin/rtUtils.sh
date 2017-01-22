#!/bin/bash
# General script with helper functions that can be included into main scripts
# Functions included:
#  - can compose and send email with the help of ssmtp util
#  - generic 'addMsg', 'writeHelper', 'sendEmail' functions
#  - can check mount point with 'checkMountPoint' function (with cookies)
#  - can check free space on device and can report it
#  - can check if rtorrent is running, if not then it starts it in tmux (with cookies)
#  - can prepare an email report based upon a function multiline output
#  - certain parts can be enabled/disabled
# Including usage in a main script: . "${BASH_SOURCE%/*}/rtUtils.sh"


# include common rT helper functions/variables
. "$HOME/.profile_rtfunctions"

###### begin: Edit ######
# directory that is mounted
MOUNTDIR="/media/chros73/wdred"

# email_from field when script sends email
EMAILFROM="username@gmail.com"
# email_to field when script sends email
EMAILTO="$EMAILFROM"
# initial prefix of subject of email, can be overriden before sourcing this script
EMAILSUBJECTPREFIX=${EMAILSUBJECTPREFIX='U - '}
###### end: Edit ######

# directory for cookies used bt scripts
RTCOOKIESDIR="$HOME/.rtcookies"
# cookie file for storing mounting errors
MAILHELPERMOUNT="$RTCOOKIESDIR/flag-mount"
# cookie file for storing rtorrent status errors
MAILHELPERRTSTATUS="$RTCOOKIESDIR/flag-status"

# string of email subject (more info can be added later to it)
SUBJECT="$EMAILSUBJECTPREFIX"
# initail string of body of email (more info can be added later to it)
MSG=""
# flag for sending email or not
EMAILSEND=false
# flag for mounting errors (false means no error)
MAILHELPERMOUNTVAL=false
# flag for rtorrent errors (false means no error)
MAILHELPERRTSTATUSVAL=false
# flag for skipping free space reporting (true means skipping)
SKIPFREESPACEMSG=false

# full path to rtorrent init script: you have to set it to be able to use it without password!
RTINITSCRIPT="/etc/init.d/rtorrent"
# full path to ssmtp util
SSMTPBIN="/usr/sbin/ssmtp"
# numfmt command with switches (converting numbers regarding to sizes)
NUMFMT=(numfmt --to=iec-i --suffix=B --format="%3f")
# full path to rtcontrol util
RTCONTROLBIN="$HOME/bin/rtcontrol"
# full path to rtxmlrpc util
RTXMLRPCBIN="$HOME/bin/rtxmlrpc"



# Function: Adds a string to an existing string variable
# Usage: addMsg VAR "String of text" (e.g.: addMsg MSG "Error: Backup!")
addMsg () {
    local MSGSEPARATOR=""
    if [ $1 = SUBJECT ]; then
	[ "$SUBJECT" != "$EMAILSUBJECTPREFIX" ] && MSGSEPARATOR=", "
    elif [ "${!1}" != "" ]; then
	MSGSEPARATOR="\n"
    fi
    read -r $1 <<< "${!1}${MSGSEPARATOR}${2}"
}


# Function: Manages cookie files (they store boolean values only: [true|false])
# Usage: writeHelper $VAL $COOKIEFILE (e.g.: writeHelper $MAILHELPERMOUNTVAL $MAILHELPERMOUNT)
writeHelper () {
    echo -n $1 > $2
}


# Function: Sends email based upon the previously set variables
# Usage: sendEmail "$MESSAGEBODY" (e.g.: sendEmail "$MSG")
sendEmail () {
    local FULLEMAIL="To: $EMAILTO\nFrom: $EMAILFROM\nSubject: $SUBJECT\n\n$1"
    echo -e "$FULLEMAIL" | "$SSMTPBIN" "$EMAILTO"
    exit
}


# Function: check rtorrent status and try to start it if it's not running
checkRtStatus () {
    # checking for rtorrent problems: is it running at all? (rtorrent will delete all the data)
    local MAILHELPERRTSTATUSVALORIG=`cat $MAILHELPERRTSTATUS`
    MAILHELPERRTSTATUSVAL=false
    if [ "$(sudo $RTINITSCRIPT status)" == "" ]; then
	# rtorrent has stopped for some reason, rty to start it then check it again
	sudo "$RTINITSCRIPT" start > /dev/null
	sleep 5
	if [ "$(sudo $RTINITSCRIPT status)" == "" ]; then
	    # rtorrent still isn't running: prepare a report about this error
	    MAILHELPERRTSTATUSVAL=true
	    if [ ! "$MAILHELPERRTSTATUSVALORIG" = true ]; then
		addMsg SUBJECT "Error: rtorrent is not running!!!!"
		addMsg MSG "Error in rtorrent: not running for some reason ... :(\n"
		addMsg MSG "Uptime: $(uptime)"
		EMAILSEND=true
	    fi
	fi
    fi
    # set rtorrent status cookie
    [[ ! "$MAILHELPERRTSTATUSVALORIG" = "$MAILHELPERRTSTATUSVAL" ]] && writeHelper $MAILHELPERRTSTATUSVAL $MAILHELPERRTSTATUS
}


# Function: get free space on device in Byte
getFreeSpace () {
    local freeSpace=$(df -P --block-size=1 "$MOUNTDIR" 2> /dev/null | grep "$MOUNTDIR" | awk '{print $4}')
    echo -e "${freeSpace:--1}"
}


# Function: Checks mount point and sends email if device is lost, also can report free space info on device
checkMountPoint () {
    # get free space in Byte
    FREESPACE=($(getFreeSpace))
    local MAILHELPERMOUNTVALORIG=`cat $MAILHELPERMOUNT`
    MAILHELPERMOUNTVAL=false
    # check for dropped device
    if [ $FREESPACE -lt 0 ] || [ ! -L "$RTHOME" ] || [ ! -e "$RTHOME" ] ; then
	MAILHELPERMOUNTVAL=true
	# prepare email about this error only if it wasn't sent already
	if [ ! "$MAILHELPERMOUNTVALORIG" = true ]; then
	    addMsg SUBJECT "Error: Mount!!!!"
	    addMsg MSG "Error in mount: probably the HDD got lost again ... :("
	    addMsg MSG "Uptime: $(uptime)"
	    EMAILSEND=true
	fi
    else
	# add info about free space on device if it's required
	[[ ! "$SKIPFREESPACEMSG" = true ]] && addMsg MSG "Free space before action: $(${NUMFMT[@]} $FREESPACE)\n"
	# check whether rtorrent is running, if not try to start it in tmux, then check its status again
	checkRtStatus
    fi
    # set mounting cookie
    [[ ! "$MAILHELPERMOUNTVALORIG" = "$MAILHELPERMOUNTVAL" ]] && writeHelper $MAILHELPERMOUNTVAL $MAILHELPERMOUNT
}


# Function: get freeable rotating space on device in Byte
getRotatingSpace () {
    let local ROTATINGSPACE=$(rtgetTotalRotatingSize)
    echo -e $FREESPACE+$ROTATINGSPACE
}


# Function: Prepares an email for reports based upon a function multiline output
# Usage: prepareReport FUNCTION ["String of subject of email"] ["String of body of email"] (e.g.: addMsg rtlistOrphans "List of Orphaned torrents" "There are orphaned torrents, manual interaction is required.")
prepareReport () {
    # do nothing if there's no function specified (1st param)
    if [ "$1" == "" ]; then
	return
    fi
    # get multiline output of a function (1st param) into array
    local LISTOFDATA=($("$1"))
    # checking for any result: if there is then prepare the email
    if [ -n "$LISTOFDATA" ]; then
	EMAILSEND=true
	# adding subject field (2nd param) if it was specified
	[ "$2" != "" ] && addMsg SUBJECT "$2"
	# adding extra text (3rd param) at the beginning of body if it was specified
	[ "$3" != "" ] && addMsg MSG "$3"
	# adding entries from array to email body line by line, dealing with the last line in a special way
	for ROW in "${LISTOFDATA[@]::${#LISTOFDATA[@]}-1}"; do
	    addMsg MSG "\t$ROW"
	done
	addMsg MSG "${LISTOFDATA[-1]}"
    fi
}


# Function: Sends the composed email if it was asked for it
checkForEmailSending () {
    if [ "$EMAILSEND" = true ] ; then
	sendEmail "$MSG"
    fi
}



# Main script: store the original IFS value and change it to newline char
OIFS=$IFS
IFS=$'\n'

# check moint point and check if an email must be sent only if it was asked for it (note: SKIPCHECKMOUNTPOINT hasn't been declared in this script, to be able to override it from a sourcing script!)
if [ ! "$SKIPCHECKMOUNTPOINT" = true ] ; then
    checkMountPoint
    checkForEmailSending
fi


