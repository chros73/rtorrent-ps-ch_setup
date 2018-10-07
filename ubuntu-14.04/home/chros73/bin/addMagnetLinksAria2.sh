#!/bin/bash
# Download and create torrent files from magnet URIs into one of the queue directories of rTorrent
#   requires: aria2c
# Usage: addMagnetLinksAria2.sh [category] "magnet:?xt=urn:btih:foo…" ["magnet:?xt=urn:btih:bar…", …]


# include common rT helper functions/variables
. "$HOME/.profile_rtfunctions"

###### begin: Edit ######
# Subcategories under the root of queue directories that we want to use
categories=(
1 "various"
2 "unsafe"
3 "apps"
4 "cartoons"
5 "ebooks"
6 "hdtv"
7 "movies"
8 "pictures"
9 "songs"
10 "load"
11 "fullseed"
12 "rotating"
)
###### end: Edit ######


# Root of queue directories for rTorrent
queue_root_dir="$RTHOME/.rtorrent/.queue"

usage_str='Usage: addMagnetLinksAria2.sh [category] "magnet:?xt=urn:btih:foo…" ["magnet:?xt=urn:btih:bar…", …]'


# check for 'aria2c' command
if ! which aria2c &>/dev/null; then
    echo "Error: You don't have 'aria2c' command available, you likely need to:"
    echo "    sudo apt-get install aria2"
    exit 1
fi

# check for arguments
if [[ -z "${1+x}" ]]; then
    echo "$usage_str"
    exit
fi


# check for optional category argument: if not set then display selection dialog
if [[ "$1" =~ xt=urn:btih:([^&/]+) ]]; then
    # check for 'dialog' command
    if ! which dialog &>/dev/null; then
        echo "Error: You don't have 'dialog' command available, you likely need to:"
        echo "    sudo apt-get install dialog"
        exit 1
    fi

    # ncursed dialog command
    dialog_cmd=(dialog --keep-tite --menu "Select category in rTorrent" 19 32 12)

    # display the category selection dialog
    choice=$("${dialog_cmd[@]}" "${categories[@]}" 2>&1 >/dev/tty)

    # check for cancel
    if [[ "$?" = 0 ]]; then
        # select the corresponding text in the array.
        category=${categories[2 * $choice - 1]}
    else
        exit
    fi

    magnets="$@"
else
    category="$1"
    magnets="${@:2:$#}"
fi


# check whether category dir exists then create a magnet torrent file
if [[ ! -d "$queue_root_dir/$category" ]]; then
    echo "Error: Selected '$queue_root_dir/$category' directory does not exist."
    exit 1
fi

# check for magnet links
if [[ "${magnets}" = "" ]]; then
    echo "Error: No magnet links are given!"
    echo "$usage_str"
    exit 1
fi


# aria2c command
aria2c_cmd=(aria2c --bt-metadata-only=true --bt-save-metadata=true -d "$queue_root_dir/$category")

# process the magnet links
for m in $magnets; do
    # check for valid magnet URI
    if [[ "$m" =~ xt=urn:btih:([^&/]+) ]]; then
        # download and create torrent file
        "${aria2c_cmd[@]}" "$m"
    else
        echo "Error: Invalid magnet URI: '$m'"
    fi
done


