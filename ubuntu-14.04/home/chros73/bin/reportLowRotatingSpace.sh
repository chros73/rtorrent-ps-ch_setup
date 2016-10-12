#!/bin/bash
# Send email report about low rotating space (in rotating and unsafe directory)
# Usage: reportLowRotatingSpace.sh


# include the helper script
. "${BASH_SOURCE%/*}/rtUtils.sh"

# subject of email report
REPORTSUBJECT="Low Rotating space"

# text for email at the beginning
REPORTBODY="There is low rotating space (in rotating and unsafe directory), manual interaction is required:"

# required rotating space (including free space as well)
REQROTATINGSPACE=750000000000		# ~ 698 GB


# checking for rtorrent problems and the existence of rtcontrol util
if [ ! "$MAILHELPERRTSTATUSVAL" = true ] && [ -L "$RTCONTROLBIN" ]; then
    # prepare report and set optional subject and text for potentional email
    let TOTALROTATINGSPACE=($(getRotatingSpace))
    if [ $TOTALROTATINGSPACE -lt $REQROTATINGSPACE ]; then
	EMAILSEND=true
	addMsg SUBJECT "$REPORTSUBJECT"
	addMsg MSG "$REPORTBODY"
	addMsg MSG "\t$(${NUMFMT[@]} $TOTALROTATINGSPACE)"
    fi
fi


# Send an email if necessary
checkForEmailSending


