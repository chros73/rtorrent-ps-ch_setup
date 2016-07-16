#!/bin/bash
# Send email report about any torrent with unusual tracker message
# Usage: reportMessages.sh


# include the helper script
. "${BASH_SOURCE%/*}/rtUtils.sh"

# subject of email report
REPORTSUBJECT="List of torrents with unusual Tracker Message"

# text for email at the beginning
REPORTBODY="There are torrents with unusual tracker message, manual interaction is required."


# checking for mounting and rtorrent problems and the existence of rtcontrol util
if [ ! "$MAILHELPERMOUNTVAL" = true ] && [ ! "$MAILHELPERRTSTATUSVAL" = true ] && [ -L "$RTCONTROLBIN" ]; then
    # prepare report and set optional subject and text for potentional email
    prepareReport rtlistMessages "$REPORTSUBJECT" "$REPORTBODY"
fi


# Send an email if necessary
checkForEmailSending


