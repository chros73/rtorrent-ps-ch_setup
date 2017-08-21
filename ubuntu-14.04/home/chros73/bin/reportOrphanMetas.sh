#!/bin/bash
# Send email report about any orphaned meta files
# Usage: reportOrphanMetas.sh


# include the helper script
. "${BASH_SOURCE%/*}/rtUtils.sh"

# subject of email report
REPORTSUBJECT="List of Orphaned meta files"

# text for email at the beginning
REPORTBODY="There are orphaned meta files, manual interaction is required."


# checking for rtorrent problems and the existence of rtcontrol util
if [ ! "$MAILHELPERRTSTATUSVAL" = true ] && [ -L "$RTCONTROLBIN" ]; then
    # prepare report and set optional subject and text for potentional email
    prepareReport rtlistOrphanMetas "$REPORTSUBJECT" "$REPORTBODY"
fi


# Send an email if necessary
checkForEmailSending


