Additions
=========


Extra Commands in rTorrent config files
---------------------------------------

d.add_to_delqueue=
^^^^^^^^^^^^^^^^^^
Adds torrent into delete queue.

d.remove_from_delqueue=
^^^^^^^^^^^^^^^^^^^^^^^
Removes torrent from delete queue.


Extra Views in rTorrent
-----------------------

=== =====================================================
Key View
=== =====================================================
 ^  ``rtcontrol``
 !  ``messages``
 t  ``trackers``
 :  ``tagged``
 <  ``datasize``
 >  ``uploadeddata``
 %  ``ratio``
 @  ``category``
 ?  ``deletable``
=== =====================================================


Extra Keyboard shortcuts in rTorrent
------------------------------------

==== =====================================================
Key  Functionality
==== =====================================================
 \*  toggle collapsed/expanded display
 #   send manual scrape request
 }   toggle ``unsafe_data``
 |   toggle selectable themes
 =   toggle autoscale network history
 .   toggle tag for a torrent
 T   clear ``tag`` view
home ``Home``
end  ``End``
pgup ``PagegUp``
pgdn ``PageDown``
==== =====================================================


Extra Bash scripts
------------------

addMagnetLink.sh
^^^^^^^^^^^^^^^^
Creates a magnet torrent file from magnet URI into one of the watch directories of rTorrent.

doBackup.sh
^^^^^^^^^^^
Backup session directory of rtorrent.



