#!/bin/bash
# Create magnet torrent files from magnet URIs into one of the watch directories of rTorrent
# Usage: addMagnetLinksNative.sh [category] "magnet:?xt=urn:btih:foo..." ["magnet:?xt=urn:btih:bar...", …]


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


# Root of watch directories that rTorrent polls
watch_root_dir="$RTHOME/.rtorrent/.downloading"

usage_str='Usage: addMagnetLinksNative.sh [category] "magnet:?xt=urn:btih:foo..." ["magnet:?xt=urn:btih:bar...", …]'


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
if [[ ! -d "$watch_root_dir/$category" ]]; then
    echo "Error: Selected '$watch_root_dir/$category' directory does not exist."
    exit 1
fi

# check for magnet links
if [[ "${magnets}" = "" ]]; then
    echo "Error: No magnet links are given!"
    echo "$usage_str"
    exit 1
fi


# process the magnet links
for m in $magnets; do
    # check for valid magnet URI
    if [[ "$m" =~ xt=urn:btih:([^&/]+) ]]; then
        # get the hash of torrent from URI
        magnet_filename="${BASH_REMATCH[1]}"

        # use the name of torrent if it's available instead of hash in filename
        if [[ "$m" =~ dn=([^&/]+) ]];then
            magnet_filename="${BASH_REMATCH[1]}"
        fi

        # create magnet torrent file
        echo "d10:magnet-uri${#m}:${m}e" > "$watch_root_dir/$category/meta-${magnet_filename}.torrent"
        echo "OK: Magnet torrent file is created '$watch_root_dir/$category/meta-${magnet_filename}.torrent'"
    else
        echo "Error: Invalid magnet URI: '$m'"
    fi
done


