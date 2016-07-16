#!/bin/bash
# Send email report about any torrent that is stopped
# Usage: reportStopped.sh


# include the helper script
. "${BASH_SOURCE%/*}/rtUtils.sh"

# subject of email report
REPORTSUBJECT="List of Stopped torrents"

# text for email at the beginning
REPORTBODY="There are stopped torrents, manual interaction is required."


# checking for mounting and rtorrent problems and the existence of rtcontrol util
if [ ! "$MAILHELPERMOUNTVAL" = true ] && [ ! "$MAILHELPERRTSTATUSVAL" = true ] && [ -L "$RTCONTROLBIN" ]; then
    # prepare report and set optional subject and text for potentional email
    prepareReport rtlistStopped "$REPORTSUBJECT" "$REPORTBODY"
fi


# Send an email if necessary
checkForEmailSending

