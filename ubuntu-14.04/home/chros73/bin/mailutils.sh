#!/bin/bash
# General script with helper functions that can be included into main scripts
# Functions included:
#  - can compose and send email with the help of ssmtp util
#  - generic 'addMsg', 'writeHelper', 'sendEmail' functions
#  - can check mount point with 'checkMountPoint' function (with cookies)
#  - can check free space on device and can report it
#  - can check if rtorrent is running, if not then it starts it in tmux
#  - can prepare an email report based upon a function multiline output
#  - certain parts can be enabled/disabled
# Including usage in a main script: . "${BASH_SOURCE%/*}/mailutils.sh"


# gets home directory (either if main script was run manually or from cron)
HOMEDIR="${BASH_SOURCE%/*}/.."
# check for valid HOME entry if not then set it (useful if it runs from cron)
[ -z "$HOME" ] && HOME="$HOMEDIR"
# include common rT helper functions
. "$HOMEDIR/.profile_functions"


###### begin: Edit ######
# directory that is mounted
MOUNTDIR="/media/chros73/wdred"
# mount point of the above directory
RTHOME="/mnt/Torrents"

# email_from field when script sends email
EMAILFROM="username@gmail.com"
# email_to field when script sends email
EMAILTO="$EMAILFROM"
# initial string of subject of email (more info can be added later to it)
SUBJECT="U -"
###### end: Edit ######


# cookie file for storing mounting errors
MAILHELPERMOUNT="$HOMEDIR/.helpers/mount.txt"
# initail string of body of email (more info can be added later to it)
MSG=""
# flag for sending email or not
EMAILSEND=false
# flag for mounting errors (false mmeans no error)
MAILHELPERMOUNTVAL=false

# flag for skipping mounting check (true means skipping)
SKIPCHECKMOUNTPOINT=false
# flag for skipping free space reporting (true means skipping)
SKIPFREESPACEMSG=false

# full path to ssmtp util
SSMTPBIN="/usr/sbin/ssmtp"
# numfmt command with switches (converting numbers regarding to sizes)
NUMFMT=(numfmt --to=iec-i --suffix=B --format="%3f")
# full path to rtcontrol util
RTCONTROLBIN="$HOMEDIR/bin/rtcontrol"
# full path to rtxmlrpc util
RTXMLRPCBIN="$HOMEDIR/bin/rtxmlrpc"


# store the original IFS value and change it to newline char
OIFS=$IFS
IFS=$'\n'


# Function: Adds a string to an existing variable
# Usage: addMsg VAR "String of text" (e.g.: addMsg MSG "Error: Backup!")
addMsg () {
    if [ "${!1}" == "" ]; then
	MSGSEPARATOR=""
    else
	MSGSEPARATOR="\n"
	if [ $1 = SUBJECT ]; then
	    MSGSEPARATOR=" "
	fi
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
    FULLEMAIL="To: $EMAILTO\nFrom: $EMAILFROM\nSubject: $SUBJECT\n\n$1"
    echo -e "$FULLEMAIL" | "$SSMTPBIN" "$EMAILTO"
    exit
}


# Function: Checks mount point and sends email if device is lost, also can report free space info on device
checkMountPoint () {
    # get free space in Byte
    FREESPACE=`df -P --block-size=1 "$MOUNTDIR" | grep "$MOUNTDIR" | awk '{print $4}'`
    MAILHELPERMOUNTVALORIG=`cat $MAILHELPERMOUNT`
    # check for device is being dropped
    if [ "$FREESPACE" == "" ] || [ ! -L "$RTHOME" ] || [ ! -e "$RTHOME" ] ; then
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
	MAILHELPERMOUNTVAL=false
	# check if rtorrent is running, if not it starts it in tmux
	sudo /etc/init.d/rtorrent start > /dev/null
    fi
    # set mounting cookie
    [[ ! "$MAILHELPERMOUNTVALORIG" = "$MAILHELPERMOUNTVAL" ]] && writeHelper $MAILHELPERMOUNTVAL $MAILHELPERMOUNT
}


# Function: Prepares an email for reports based upon a function multiline output
# Usage: prepareReport FUNCTION ["String of subject of email"] ["String of body of email"] (e.g.: addMsg rtlistOrphans "List of Orphaned torrents" "There are orphaned torrents, manual interaction is required.")
prepareReport () {
    # do nothing if there's no function specified (1st param)
    if [ "$1" == "" ]; then
	return
    fi
    # get multiline output of a function (1st param) into array
    LISTOFDATA=($("$1"))
    # checking for any result: if there is then prepare the email
    if [ -n "$LISTOFDATA" ]; then
	EMAILSEND=true
	# adding subject field (2nd param) if it was specified
	[ "$2" != "" ] && addMsg SUBJECT "$2"
	# adding extra text (3rd param) at the beginning of body if it was specified
	[ "$3" != "" ] && addMsg MSG "$3"
	# adding entries in array to email body line by line
	for ROW in "${LISTOFDATA[@]}"; do
	    addMsg MSG "$ROW"
	done
    fi
}


# Function: Sends the composed email if it was asked for it
checkForEmailSending () {
    if [ "$EMAILSEND" = true ] ; then
	sendEmail "$MSG"
    fi
}




# Main script: It will check moint point and check if an email must be sent only if it was asked for it
if [ ! "$SKIPCHECKMOUNTPOINT" = true ] ; then
    checkMountPoint
    checkForEmailSending
fi


