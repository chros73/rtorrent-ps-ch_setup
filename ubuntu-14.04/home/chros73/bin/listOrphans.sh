#!/bin/bash
# Listing orphaned torrents
# Usage: listOrphans.sh


# name of helper script that will be included
MAILUTILSSCRIPT="mailutils.sh"
# include the script
. "${BASH_SOURCE%/*}/$MAILUTILSSCRIPT"


# python template file to generate the list
ORPHANSTEMPLATE="orphans-ch.txt"

# full path to rtcontrol util
RTCONTROLBIN="$HOMEDIR/bin/rtcontrol"
# rtcontrol command with switches
RTCONTROL=($RTCONTROLBIN -qO $ORPHANSTEMPLATE \*)

# do not report free space
SKIPFREESPACEMSG=true


# checking for mounting problems and the existence of rtcontrol util
if [ ! "$MAILHELPERMOUNTVAL" = true ] && [ -L "$RTCONTROLBIN" ]; then
    # get multiline output (from python template) into array
    LISTOFORPHANS=($("${RTCONTROL[@]}"))

    # checking for any result: if there is then prepare the email
    if [ -n "$LISTOFORPHANS" ]; then
	EMAILSEND=true
	addMsg SUBJECT "List of Orphaned torrents"
	for ROW in "${LISTOFORPHANS[@]}"; do
	    addMsg MSG "$ROW"
	done
    fi
fi


# Send an email if necessary
checkForEmailSending


