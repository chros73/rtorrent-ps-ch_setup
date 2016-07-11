#!/bin/bash
# General script with helper functions that can be included into main scripts
# Functions included:
#  - can compose and send email with the help of ssmtp util
#  - generic 'addMsg', 'writeHelper', 'sendEmail' functions
#  - can check mount point with 'checkMountPoint' function (with cookies)
#  - can check free space on device and can report it
#  - can check if rtorrent is running, if not then it starts it in tmux
#  - certain parts can be enabled/disabled
# Including usage in a main script: . "${BASH_SOURCE%/*}/mailutils.sh"


# gets home directory (either if main script was run manually or from cron)
HOMEDIR="${BASH_SOURCE%/*}/.."

###### begin: Edit ######
# directory that is mounted
MOUNTDIR="/media/chros73/wdred"
# mount point of the above directory
CHECKDIR="$MOUNTDIR/Torrents"

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
    if [ "$FREESPACE" == "" ] || [ ! -d "$CHECKDIR" ] ; then
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


