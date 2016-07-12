#!/bin/bash
# Send email report about any torrent with unusual tracker message
# Usage: reportMessages.sh


# name of helper script that will be included
MAILUTILSSCRIPT="mailutils.sh"
# include the script
. "${BASH_SOURCE%/*}/$MAILUTILSSCRIPT"


# subject of email report
REPORTSUBJECT="List of torrents with unusual Tracker Message"

# text for email at the beginning
REPORTBODY="There are torrents with unusual tracker message, manual interaction is required.\n"


# checking for mounting problems and the existence of rtcontrol util
if [ ! "$MAILHELPERMOUNTVAL" = true ] && [ -L "$RTCONTROLBIN" ]; then
    # prepare report and set optional subject and text for potentional email
    prepareReport rtlistMessages "$REPORTSUBJECT" "$REPORTBODY"
fi


# Send an email if necessary
checkForEmailSending


