#!/bin/bash
# Send email report about any public torrent
# Usage: reportPublic.sh


# include the helper script
. "${BASH_SOURCE%/*}/rtUtils.sh"

# subject of email report
REPORTSUBJECT="List of Public torrents"

# text for email at the beginning
REPORTBODY="There are public torrents, manual interaction is required."


# checking for rtorrent problems and the existence of rtcontrol util
if [ ! "$MAILHELPERRTSTATUSVAL" = true ] && [ -L "$RTCONTROLBIN" ]; then
    # prepare report and set optional subject and text for potentional email
    prepareReport rtlistPublic "$REPORTSUBJECT" "$REPORTBODY"
fi


# Send an email if necessary
checkForEmailSending


