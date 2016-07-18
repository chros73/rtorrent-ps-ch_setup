#!/bin/bash
# Sample download script to demonstrate usage of inclusion of queue script inside a main script
# It can be useful to include the queue script into a downloading script: we don't have to wait for cron to run the queue script but this script fires it up instead.
# Usage: sampleDownload.sh


# disbale running queue script during inclusion: run it directly after gathering all the data (note: it has to be defined before inclusion!)
SKIPMANAGEQUEUE=true
# include the queue script
. "${BASH_SOURCE%/*}/queueTorrent.sh"
# disable email reporting about queued torrents: prepare reporting in this script instead (note: all similar options have to be defined after inclusion!)
SKIPQUEUESTATS=true



# override the default subject of email report (more info can be appanded to it later)
SUBJECT="Ubuntu -"
# Define more necessary variables (note: these are commented out in this sample script)
: '
# some info
FOO="xcv"
# some info
BAR="bnm"
'



# Define necessary functions (note: the content of these are commented out in this sample script and they won't work)

# some info
downloadTorrents () {
: '
    # initialize temp download message for the downloaded data: to be able to insert them altogether into email report
    local TEMPMSGDOWN=""

    # fire up some download command and put the metafiles into one of the "rotating", "unsafe" dirs in ".queue" dir (these are involved in auto-rotating)

    # prepare email report about them
    for DOWNLOAD in ${DOWNLOADS[@]}; do
	addMsg TEMPMSGDOWN "\t$DOWNLOAD"
    done

    # add more subject info, some generic info and  download temp message into main email body if there is any
    if [ "$TEMPMSGDOWN" != "" ]; then
	addMsg SUBJECT "Downloaded torrents"
	addMsg MSG "Downloaded torrents has been put into one of the subdirs of .queue dir.\n"
	addMsg MSG "$TEMPMSGDOWN\n"
	# 
	EMAILSEND=true
    fi
'
}


# more funtion
addMoreInfo () {
: '
    # do more magic here

    # then add more info to email report
    if [ $DOWNSIZE -gt 800000000 ] ; then
	addMsg SUBJECT "Huge amount of data!"
	addMsg MSG "Downloadable data size: $(${NUMFMT[@]} $DOWNSIZE)"
    fi
'
}



# Main script: run a function before running queue script, run the queue script, then run an another function, then send the email report (if necessary)
downloadTorrents
manageQueue
addMoreInfo
checkForEmailSending



