#!/bin/bash
# Backup session directory of rtorrent
# Usage: doBackup.sh


# include the helper script
. "${BASH_SOURCE%/*}/rtUtils.sh"

###### begin: Edit ######
# reserve only the last 10 backups
BACKUP_ROTATE=10
# include config file for backup directories
INCLUDECONF='doBackupIncl.conf'
# exclude config file for backup directories
EXCLUDECONF='doBackupExcl.conf'
# relative path of output directory
OUTPUT_DEVDIR='backup/rtorrent-session'
# full path to output directory
OUTPUT_DIR="$MOUNTDIR/$OUTPUT_DEVDIR"
# name of backup file
OF="$(date +%Y%m%d_%H%M)-session.tar.gz"
###### end: Edit ######



# checking for mounting problems
if [ ! "$MAILHELPERMOUNTVAL" = true ]; then
    # save session before backup if rtxmlrpc util exists and rtorrent is running then wait for 5 seconds to be able to complete it
    [ -L "$RTXMLRPCBIN" ] && [ ! "$MAILHELPERRTSTATUSVAL" = true ] && "$RTXMLRPCBIN" --cron session.save &>/dev/null && sleep 5
    # backup session directory of rtorrent
    tar -czf "$OUTPUT_DIR/$OF" --exclude-from="$HOME/bin/$EXCLUDECONF" --files-from "$HOME/bin/$INCLUDECONF"

    # delete old backups if the backup was successful
    if [ $? -eq 0 ] ; then
	find "$OUTPUT_DIR/" -type f -iname \*.tar.gz \! -mtime -$BACKUP_ROTATE -delete
    # prepare an email if it wasn't
    else
	EMAILSEND=true
	addMsg SUBJECT "Error: Backup!"
	addMsg MSG "Something went wrong during backup :( \n"
    fi
fi


# Send an email if necessary
checkForEmailSending


