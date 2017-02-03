#!/bin/bash
# Creates a magnet torrent file from magnet URI into one of the watch directories of rTorrent
# Usage: addMagnetLink.sh "magnet:?xt=urn:btih:foobar..."


# include common rT helper functions/variables
. "$HOME/.profile_rtfunctions"

###### begin: Edit ######
# Subcategories under the root of watch directories that we want to use
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


# Root of watch directories that rTorrent polls.
watch_root_dir="$RTHOME/.rtorrent/.downloading"


# check for valid magnet URI
if [[ "$1" =~ xt=urn:btih:([^&/]+) ]]; then
    magnet_url="$1"
    # get the hash of torrent from URI
    magnet_filename="${BASH_REMATCH[1]}"
    # use the name of torrent if it's available instead of hash in filename
    if [[ "$1" =~ dn=([^&/]+) ]];then
	magnet_filename="${BASH_REMATCH[1]}"
    fi
else
    echo "Error: Invalid magnet URI."
    exit 1
fi


# ncursed dialog command
dialog_cmd=(dialog --keep-tite --menu "Select category in rTorrent" 19 32 12)

# display the category selection dialog
choice=$("${dialog_cmd[@]}" "${categories[@]}" 2>&1 >/dev/tty)


# check for cancel
if [ "$?" = 0 ]; then
    # select the corresponding text in the array.
    category=${categories[2 * $choice - 1]}
    # check whether category dir exists then create a magnet torrent file
    if [ -d "$watch_root_dir/$category"  ]; then
	echo "d10:magnet-uri${#magnet_url}:${magnet_url}e" > "$watch_root_dir/$category/meta-${magnet_filename}.torrent"
	echo "Magnet torrent file was created in $watch_root_dir/$category directory."
    else
	echo "Error: Selected $watch_root_dir/$category directory doesn't exist."
    fi
fi


