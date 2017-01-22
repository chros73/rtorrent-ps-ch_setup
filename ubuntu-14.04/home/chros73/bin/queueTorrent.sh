#!/bin/bash
# Queue management script with rotating (deleting data) capability and category support (that can be included into a main script as well)
# 1. Downloading queue manager: moves meta files from one of the subdirs of .queue dir into one of the subdirs of .downloading dir (so rtorrent can start to download them)
#   - its top priority is that it shouldn't break rtorrent in any case
#   - checks how many meta files are in the .downloading dir: means what the number of active downloads is currently and moves the appropriate number of meta files from one of the subdirs of .queue dir
#   - size of downloading queue and order of processing is configurable
#   - doesn't move meta file(s) if:
#     - rtorrent stopped running
#     - there's not enough disk space for the queueable torrents (even after trying to make more)
#     - target data dir/file (in incomplete dir) OR meta file exists (in one of the subdirs of .downloading dir), in this case move meta file into .duplicated dir and append current time to its filename
#   - it runs disk free space manager every time (except for when rtorrent is stopped)
#   - it can send report about all the action that was made (some of them are configurable)
# 2. Disk free space manager: deletes meta files from the predefined rotating, unsafe category dirs and from .delqueue dir (so rtorrent can delete their data)
#   - rtorrent is configured to only delete their data if their unsafe_data custom variable is set to [1|2] !
#   - processing order is the following:
#     - deletes meta files from .delqueue dir in reverse order (oldest first)
#     - deletes meta files from the predefined rotating, unsafe category dirs in reverse order (oldest first), handling them altogether
#   - enabling this part of the script is configurable (disabled by default for safety reasons with AUTOROTATETORRENTS=false)
#   - doesn't delete meta file(s) if:
#     - this functionality is disabled
#     - there's enough disk space
#     - there's nothing to be deleted from the defined rotating, unsafe categories and .delqueue dir
#   - it should run by the downloading queue manager
#   - amount of reserved disk space is configurable
#   - it should wait for 15 seconds after successful deletion for letting rtorrent to finish deleting data
#   - it can send report about all the deleted torrents (configurable)
# Usage: queueTorrent.sh
#   - or including in a main script: . "${BASH_SOURCE%/*}/queueTorrent.sh"


# include the helper script
. "${BASH_SOURCE%/*}/rtUtils.sh"

###### begin: Edit ######
# size of downloading queue: number of allowed active downloads
QUEUESIZE=9
# order of processing queue: '' for normal (newest first) or 'r' is reverse (oldest first)
QUEUEORDER=""
# enable/disable email reporting about bogus torrents, value: [true|false]
SKIPBOGUSSTATS=false
# enable/disable email reporting about duplicated torrents, value: [true|false]
SKIPDUPLSTATS=false
# enable/disable email reporting about too big torrents, value: [true|false]
SKIPBIGSTATS=false
# enable/disable email reporting about queued torrents, value: [true|false]
SKIPQUEUESTATS=false

# enable/disable deleting torrents in queue manager, value: [true|false]; it's disabled by default for safety reasons
AUTOROTATETORRENTS=false
# amount of reserved disk space in GiB (this value should depend on the max download speed of rtorrent AND how often this queue script will run from cron)
DISKSPACELIMIT=4
# enable/disable email reporting about deleted torrents, value: [true|false] (recommended value: false)
SKIPDELETESTATS=false
###### end: Edit ######

# main directory for management
MAINDIR="$RTHOME/.rtorrent"
# queue directory
QUEUEDIR="$MAINDIR/.queue"
# downloading directory
DOWNLOADINGDIR="$MAINDIR/.downloading"
# completed directory
COMPLETEDIR="$MAINDIR/.completed"
# delete-queue directory
DELQUEUEDIR="$MAINDIR/.delqueue"
# bogus directory
BOGUSDIR="$MAINDIR/.bogus"
# duplicated directory
DUPLICATEDDIR="$MAINDIR/.duplicated"
# oversized directory
OVERSIZEDDIR="$MAINDIR/.oversized"
# rotating directory
DOWNSUBDIR="rotating"
# unsafe directory
DOWNRESTSUBDIR="unsafe"

# defining deletable array: adding 'delqueue', ('rotating' and 'unsafe') dirs to it
declare -a DELQUEUEARR
DELQUEUEARR+=("$DELQUEUEDIR")
DELQUEUEARR+=("$COMPLETEDIR/$DOWNSUBDIR $COMPLETEDIR/$DOWNRESTSUBDIR")

# cookie file for storing disk space errors
MAILHELPERSPACE="$RTCOOKIESDIR/flag-space"

# lstor command with switches (for getting size in Byte or name of a torrent from its meta file)
LSTORGETSIZE=($HOME/bin/lstor --cron -qVo __size__)
LSTORGETNAME=($HOME/bin/lstor --cron -qVo info.name)

# initialize total size of data
let TDOWNSIZE=0



# Function: Deletes meta files from the defined delete array dirs (so rtorrent can delete their data), based upon the previously set variables (run by manageQueue function)
makeFreeSpace () {
    # checking whether it should even start deletion process: we have enough space or it can be disabled with AUTOROTATETORRENTS variable
    if [ $FREESPACE -le $REQSPACE ] && [ "$AUTOROTATETORRENTS" = true ]; then
	let local DELSIZE=0
	# initialize temp delete message for the deleted data: to be able to insert them altogether at the beginning of an email report later
	local TEMPMSGDEL=""
	# size of data that should be deleted
	let local DELSIZEREQ=$REQSPACE-$FREESPACE
	# let's go through the defined deletable directories, check for oldest in: 'delqueue' first, then in 'rotating' and 'unsafe' altogether!
	for DELDIR in "${DELQUEUEARR[@]}"; do
	    # sets back the original IFS (we need this to be able to handle 2 or more directories altogether)
	    IFS=$OIFS
	    local DELDIRMOD=($DELDIR)		# variable without "" !!! dealing with multiple dirs to be able to sort files in them at the same time
	    # change IFS to newline char again
	    IFS=$'\n'
	    # getting the list of meta file paths in the selected directory(s)
	    for METAFILEPATH in $(ls -1tr $(for DIRMOD in ${DELDIRMOD[@]}; do echo -e "$DIRMOD/*.torrent" ;done) 2>/dev/null); do
		# checking whether we need more
		if [ $DELSIZE -gt $DELSIZEREQ ]; then
		    # to break out the outer for loop as well if we don't
		    break 2
		fi
		# getting the name of meta file from full path for logging purposes (!!! dealing with multiple dirs hence the 2 substitution)
		for DIRMOD in ${DELDIRMOD[@]}; do
		    local METAFILE="${METAFILEPATH#$DIRMOD/}"	# unsafe
		    METAFILE="${METAFILE#$DELDIRMOD/}"		# delqueue & rotating
		done
		# simply delete broken (already deleted) symlink in .delqueue dir
		if [ "$DELDIR" == "$DELQUEUEDIR" ] && [ ! -e "$METAFILEPATH" ]; then
		    rm -f "$METAFILEPATH"
		    # checking whether it should include deleted data stats in email report
		    if [ ! "$SKIPDELETESTATS" = true ]; then
			addMsg TEMPMSGDEL "\t0 - $METAFILE\n\t\tTarget of this symlink has been already deleted."
		    fi
		else
		    # name of torrent (with the help of lstor)
		    local DATANAME=$(${LSTORGETNAME[@]} "$METAFILEPATH" 2>/dev/null)
		    # data size of torrent (with the help of lstor), set it to 0 if an error occurred
		    local DATASIZE=$(${LSTORGETSIZE[@]} "$METAFILEPATH" 2>/dev/null)
		    DATASIZE=${DATASIZE:-0}
		    # total deletable data size so far
		    let DELSIZE=$DELSIZE+$DATASIZE
		    # delete the meta file itself (rtorrent will delete the data): in the case of '.delqueue' dir handle symlinks
		    if [ "$DELDIR" == "$DELQUEUEDIR" ]; then
			rm "`readlink -f "$METAFILEPATH"`" "$METAFILEPATH"
		    else
			rm -f "$METAFILEPATH"
		    fi
		    # checking whether it should include deleted data stats in email report
		    if [ ! "$SKIPDELETESTATS" = true ]; then
			# add the name of meta file to the report if it's not the same as the name of data dir/file
			local METAFILENAMEMSG=""
			if [ "$DATANAME.torrent" != "$METAFILE" ]; then
			    METAFILENAMEMSG="\n\t\t($METAFILE)"
			fi
			# add more info if the meta file was invalid for whatever reason
			local METAFILESIZEMSG=""
			if [ $DATASIZE -le 0 ] || [ -z $DATANAME ]; then
			    METAFILESIZEMSG="\n\t\t(Torrent (meta) file was bogus!)"
			fi
			addMsg TEMPMSGDEL "\t$(${NUMFMT[@]} $DATASIZE) - $DATANAME$METAFILENAMEMSG$METAFILESIZEMSG"
		    fi
		fi
	    done
	done
	# add deleted temp message into main email body if there's any
	if [ "$TEMPMSGDEL" != "" ]; then
	    addMsg SUBJECT "Making Free space"
	    # add info about the size of required deleted data
	    addMsg MSG "Deleted torrents (free space required: $(${NUMFMT[@]} $DISKSPACELIMITINBYTE) + $(${NUMFMT[@]} $TDOWNSIZE) - $(${NUMFMT[@]} $FREESPACE) = $(${NUMFMT[@]} $DELSIZEREQ)):"
	    # add the composed temp string to the email body
	    addMsg MSG "$TEMPMSGDEL"
	    # add a summary about the deleted size to the email body
	    addMsg MSG "Deleted data size: $(${NUMFMT[@]} $DELSIZE)\n\n"
	    EMAILSEND=true
	fi
	# wait 15 seconds after deletion (just in case, to let rtorrent to finish the job)
	[ $DELSIZE -gt 0 ] && sleep 15
    fi
}



# Function: moves meta files from one of the subdirs of '.queue' dir into one of the subdirs of '.downloading' dir (so rtorrent can start to download them), runs makeFreeSpace function
manageQueue () {
    # check whether rtorrent runs at all: if not then don't process anything (rtUtils script should have started it if it hasn't run but e.g. it can be a hardware problem)
    [ "$MAILHELPERRTSTATUSVAL" = true ] && return 1

    # size of reserved disk space in Byte
    let DISKSPACELIMITINBYTE=$((DISKSPACELIMIT *1024 * 1024 * 1024))
    let REQSPACE=$DISKSPACELIMITINBYTE
    # number of torrents waiting to be moved to downloading
    local CURRENTTEMPSIZE=`find "$QUEUEDIR" -type f -iname \*.torrent | wc -l`
    if [ $CURRENTTEMPSIZE -gt 0 ] ; then
	# number of torrents currently downloading
	local CURRENTQUEUESIZE=`find "$DOWNLOADINGDIR" -type f -iname \*.torrent | wc -l`
	# size of free slots left in downloading queue: if it's full (=0) then do nothing (just call makeFreeSpace function, just in case)
	let local SLOTSLEFTINQUEUE=$QUEUESIZE-$CURRENTQUEUESIZE
	if [ $SLOTSLEFTINQUEUE -gt 0 ]; then
	    # initialize temp bogus, duplicated, oversized and queue message, moved torrents counter, temparray to hold full path of moveable meta files
	    declare -a local MSGVARARR=("Bogus" "Duplicated" "Oversized")
	    for MSGVAR in "${MSGVARARR[@]}"; do
		local TEMPMSG$MSGVAR=""
	    done
	    local TEMPMSGQUEUE=""
	    let local MOVEDTORRENTS=0
	    declare -a local TEMPARR
	    # getting total freeable space (accounting reserved disk space as well)
	    let local TOTALROTATINGSPACE=($(getRotatingSpace))-$DISKSPACELIMITINBYTE
	    # gather up total size information only about the number of slots of torrents to be able to process by makeFreeSpace function, sort by QUEUEORDER variable
	    for FILEPATH in $(ls -1t$QUEUEORDER $(find "$QUEUEDIR" -type f -iname \*.torrent) | head -n$SLOTSLEFTINQUEUE) ; do
		# name of torrent (with the help of lstor)
		local DATANAME=$(${LSTORGETNAME[@]} "$FILEPATH" 2>/dev/null)
		# sub-path of meta file (including name of category dir)
		local METAFILESUBPATH="${FILEPATH#$QUEUEDIR/}"
		# data size of torrent (with the help of lstor), set it to 0 if an error occurred
		local DATASIZE=$(${LSTORGETSIZE[@]} "$FILEPATH" 2>/dev/null)
		DATASIZE=${DATASIZE:-0}
		# checking whether torrent (meta) file is bogus
		if [ $DATASIZE -le 0 ] || [ -z $DATANAME ]; then
		    # it is bogus, move meta file into bogus dir, append current date and time to the filename, prepare a report about this problem
		    mv -f "$FILEPATH" "$BOGUSDIR/${METAFILESUBPATH##*/}-$(date +%Y%m%d_%H%M)"
		    # checking whether it should include bogus stats in email report
		    if [ ! "$SKIPBOGUSSTATS" = true ]; then
			addMsg TEMPMSGBogus "\t$(${NUMFMT[@]} $DATASIZE) - $DATANAME\n\t\t${METAFILESUBPATH##*/}"
		    fi
		# checking whether target data/meta dir/file exists in 'incomplete', 'downloading/*' dirs
		elif [ -e "$RTINCOMPLETEDIR/$DATANAME" ] || [ -f "$DOWNLOADINGDIR/$METAFILESUBPATH"  ]; then
		    # one of them is there (or both), move meta file into duplicated dir, append current date and time to the filename, prepare a report about this problem
		    mv -f "$FILEPATH" "$DUPLICATEDDIR/${METAFILESUBPATH##*/}-$(date +%Y%m%d_%H%M)"
		    # checking whether it should include duplicated stats in email report
		    if [ ! "$SKIPDUPLSTATS" = true ]; then
		        addMsg TEMPMSGDuplicated "\t$(${NUMFMT[@]} $DATASIZE) - $DATANAME\n\t\t${METAFILESUBPATH##*/}"
		    fi
		# checking whether current torrent size is oversized
		elif [ $TOTALROTATINGSPACE -lt $DATASIZE ]; then
		    # it's oversized, move meta file into oversized dir, append current date and time to the filename, prepare a report about this problem
		    mv -f "$FILEPATH" "$OVERSIZEDDIR/${METAFILESUBPATH##*/}-$(date +%Y%m%d_%H%M)"
		    # checking whether it should include duplicated stats in email report
		    if [ ! "$SKIPBIGSTATS" = true ]; then
			addMsg TEMPMSGOversized "\t$(${NUMFMT[@]} $TOTALROTATINGSPACE) / $(${NUMFMT[@]} $DATASIZE) - $DATANAME\n\t\t${METAFILESUBPATH##*/}"
		    fi
		else
		    # neither of them exist, we are good to go: total downloadable data size so far
		    let TDOWNSIZE=$TDOWNSIZE+$DATASIZE
		    # decrease total freeable space
		    let TOTALROTATINGSPACE=$TOTALROTATINGSPACE-$DATASIZE
		    # increase the moved torrents counter for reporting purposes
		    let MOVEDTORRENTS=$((MOVEDTORRENTS + 1))
		    # store the full path of meta file in the array
		    TEMPARR+=("$FILEPATH")
		    # checking whether it should include stats in email report: useful to disable it when a main script handles the report
		    if [ ! "$SKIPQUEUESTATS" = true ]; then
			# add the name of meta file to the report if it's not the same as the name of data dir/file
			local METAFILENAMEMSG=""
			if [ "$DATANAME.torrent" != "${METAFILESUBPATH##*/}" ]; then
			    METAFILENAMEMSG="\n\t\t(${METAFILESUBPATH##*/})"
			fi
			addMsg TEMPMSGQUEUE "\t$(${NUMFMT[@]} $DATASIZE) - $DATANAME$METAFILENAMEMSG"
		    fi
		fi
	    done
	    # add bogus, duplicated, oversized temp messages into main email body if there's any
	    for MSGVAR in "${MSGVARARR[@]}"; do
		# create a temp variable for the composed variable name to be able to use it with variable indirection in condition
		local MSGVARNAME="TEMPMSG$MSGVAR"
		if [ "${!MSGVARNAME}" != "" ]; then
		    addMsg SUBJECT "$MSGVAR torrents!"
		    addMsg MSG "$MSGVAR torrents has been moved to into ${MSGVAR,} directory, manual interaction is required."
		    # add the composed temp string to the email body
		    addMsg MSG "${!MSGVARNAME}\n\n"
		    EMAILSEND=true
		fi
	    done

	    # size of required disk space
	    let REQSPACE=$REQSPACE+$TDOWNSIZE
	    # call makeFreeSpace function to delete meta files if necessary
	    makeFreeSpace

	    # checking for enough disk space: if there's still not enough space (e.g. size of all the deletable data was smaller than required) that all the selected torrents requires: don't process them, and make an email report about this error
	    local NEWFREESPACE=($(getFreeSpace))
	    local MAILHELPERSPACEVALORIG=`cat $MAILHELPERSPACE`
	    if [ $NEWFREESPACE -gt $REQSPACE ]; then
		# deletion was successful, move the previously seletced meta files from queue dir into downloading dir
		MAILHELPERSPACEVAL=false
		for QMETAFILEPATH in "${TEMPARR[@]}"; do
		    # sub-path of meta file (including name of category dir)
		    local QMETAFILESUBPATH="${QMETAFILEPATH#$QUEUEDIR/}"
		    # move meta file into its place in downloading dir
		    mv -f "$QMETAFILEPATH" "$DOWNLOADINGDIR/$QMETAFILESUBPATH"
		done
		# checking whether it should send email report: useful to disable it when a main script handles the report
		if [ ! "$SKIPQUEUESTATS" = true ] && [ $MOVEDTORRENTS -gt 0 ]; then
		    addMsg SUBJECT "Queued $MOVEDTORRENTS torrents"
		    addMsg MSG "Queued $MOVEDTORRENTS torrents:"
		    # add the composed temp string to the email body
		    addMsg MSG "$TEMPMSGQUEUE\n"
		    # add a summary about the downloadable data size to the email body
		    addMsg MSG "Downloadable data size: $(${NUMFMT[@]} $TDOWNSIZE)"
		    EMAILSEND=true
		fi
	    else
		# deletion was unsuccessful, prepare a report about this error
		MAILHELPERSPACEVAL=true
		if [ ! "$MAILHELPERSPACEVALORIG" = true ]; then
		    addMsg SUBJECT "Error: insufficient disk space!!!!"
		    addMsg MSG "Error in disk space: deleting from rotating directories wasn't enough... :("
		    addMsg MSG "\tYou have to fix it manually :("
		    addMsg MSG "Uptime: $(uptime)"
		    EMAILSEND=true
		fi
	    fi
	    # set disk space cookie
	    [[ ! "$MAILHELPERSPACEVALORIG" = "$MAILHELPERSPACEVAL" ]] && writeHelper $MAILHELPERSPACEVAL $MAILHELPERSPACE
	else
	    # run makeFreeSpace even when the downloading queue is full: it will check for the DISKSPACELIMIT size in this case (useful when disk space was reported wrongly for some reason)
	    makeFreeSpace
	fi
    else
        # run makeFreeSpace even when there is nothing in the queue: it will check for the DISKSPACELIMIT size in this case (useful when disk space was reported wrongly for some reason)
        makeFreeSpace
    fi
}



# Main script: start the queue manager and check if an email must be sent only if it was asked for it (note: SKIPMANAGEQUEUE hasn't been declared in this script, to be able to override it from a sourcing script!)
if [ ! "$SKIPMANAGEQUEUE" = true ] ; then
    manageQueue
    checkForEmailSending
fi


