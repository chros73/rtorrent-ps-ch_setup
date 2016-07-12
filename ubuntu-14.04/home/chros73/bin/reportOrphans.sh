#!/bin/bash
# Send email report about any orphaned torrent
# Usage: reportOrphans.sh


# name of helper script that will be included
MAILUTILSSCRIPT="mailutils.sh"
# include the script
. "${BASH_SOURCE%/*}/$MAILUTILSSCRIPT"


# subject of email report
REPORTSUBJECT="List of Orphaned torrents"

# text for email at the beginning
REPORTBODY="There are orphaned torrents, manual interaction is required.\n"


# checking for mounting problems and the existence of rtcontrol util
if [ ! "$MAILHELPERMOUNTVAL" = true ] && [ -L "$RTCONTROLBIN" ]; then
    # prepare report and set optional subject and text for potentional email
    prepareReport rtlistOrphans "$REPORTSUBJECT" "$REPORTBODY"
fi


# Send an email if necessary
checkForEmailSending


