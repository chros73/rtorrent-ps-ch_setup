#!/bin/bash
# Send email report about any orphaned torrent
# Usage: reportOrphans.sh


# include the helper script
. "${BASH_SOURCE%/*}/rtUtils.sh"

# subject of email report
REPORTSUBJECT="List of Orphaned torrents"

# text for email at the beginning
REPORTBODY="There are orphaned torrents, manual interaction is required."


# checking for rtorrent problems and the existence of rtcontrol util
if [ ! "$MAILHELPERRTSTATUSVAL" = true ] && [ -L "$RTCONTROLBIN" ]; then
    # prepare report and set optional subject and text for potentional email
    prepareReport rtlistOrphans "$REPORTSUBJECT" "$REPORTBODY"
fi


# Send an email if necessary
checkForEmailSending


