Additions
=========

.. contents:: **Contents**


Extra Commands in rTorrent config files
---------------------------------------

d.add_to_delqueue=
^^^^^^^^^^^^^^^^^^
Adds torrent into delete queue.

d.remove_from_delqueue=
^^^^^^^^^^^^^^^^^^^^^^^
Removes torrent from delete queue.


Standard Views in rTorrent
--------------------------

===  ==============  =======  =========  =============================
Key  View            Updated  Collapsed  Sorting, filtering properties
===  ==============  =======  =========  =============================
 1   ``main``        20 sec   *          sorted by ``downloaded time`` desc
 2   ``name``        20 sec   *          sorted by ``name``
 3   ``started``     20 sec   *          sorted by ``last active`` desc, group by ``complete``, ``throttle``, ``download and upload speed`` desc
 4   ``stopped``              *          sorted by ``downloaded time`` desc, group by ``complete``, ``throttle``
 5   ``complete``             *          sorted by ``completed time`` desc
 6   ``incomplete``           *          sorted by ``download and upload speed`` desc, group by ``open`` desc, ``throttle``
 7   ``hashing``                         sorted by ``loaded time`` desc, group by ``throttle``
 8   ``seeding``      20 sec  *          sorted by ``upload speed`` desc, group by ``throttle``, only torrents with peers are shown
 9   ``leeching``    20 sec              sorted by ``download and upload speed`` desc, group by ``throttle``, only torrents with peers are shown
 0   ``active``      20 sec   *          sorted by ``download and upload speed`` desc, group by ``open`` desc, ``throttle``, ``complete`` desc, only active or incomplete torrents are shown
===  ==============  =======  =========  =============================


Extra Views in rTorrent
-----------------------

===  ================  =========  =============================
Key  View              Collapsed  Sorting, filtering properties
===  ================  =========  =============================
 ^   ``rtcontrol``     *          
 !   ``messages``      *          sorted by ``downloaded time``, group by ``throttle``, ``message``
 t   ``trackers``      *          sorted by ``downloaded time`` desc, group by ``domain``
 :   ``tagged``        *          
 <   ``datasize``      *          sorted by ``data size`` desc
 >   ``uploadeddata``  *          sorted by ``uploaded data`` desc, ``downloaded time`` desc
 %   ``ratio``         *          sorted by ``ratio`` desc, ``uploaded data`` desc, ``downloaded time`` desc
 @   ``category``      *          sorted by ``category``, ``name``
 ?   ``deletable``     *          sorted by ``downloaded time``, group by ``unsafe_data`` desc, ``throttle`` desc, only deletable torrents are shown
===  ================  =========  =============================


Extra Keyboard shortcuts in rTorrent
------------------------------------

====  ========================================
Key   Functionality
====  ========================================
 }    toggle ``unsafe_data`` for a torrent
 #    send manual scrape request for a torrent
 .    toggle tag for a torrent
 T    clear ``tag`` view
 \*   toggle collapsed/expanded display
 \|   toggle selectable themes
 =    toggle autoscale network history
home  Home
end   End
pgup  Pageg Up
pgdn  Page Down
====  ========================================


Extra Bash functions
--------------------

rtlistOrphans
^^^^^^^^^^^^^
List orphaned torrents.

Usage: ``rtlistOrphans``

rtlistStuck
^^^^^^^^^^^
List stuck torrents in incomplete directory.

Usage: ``rtlistStuck``

rtlistMessages
^^^^^^^^^^^^^^
List torrents with unusual trackers messages.

Usage: ``rtlistMessages``

rtlistStopped
^^^^^^^^^^^^^
list stopped torrents.

Usage: ``rtlistStopped``


Extra Bash scripts
------------------

addMagnetLink.sh
^^^^^^^^^^^^^^^^
Creates a magnet torrent file from magnet URI into one of the watch directories of rTorrent.

Usage: ``addMagnetLink.sh "magnet:?xt=urn:btih:foobar..."``

doBackup.sh
^^^^^^^^^^^
Backup session directory of rtorrent.

Usage: ``doBackup.sh``

getLimits.sh
^^^^^^^^^^^^
Calculates uprate limit for slowup throttle or global downrate limit based on the parameters or gives info about them. It's used by ``adjust_throttle_slowup=``, ``adjust_throttle_global_down_max_rate`` scheduled tasks and ``i=`` method in rtorrent.

Usage: ``getLimits.sh <<action>> <<global_upload_rate>> <<throttle_upload_rate>> [throttle_upload_limit]``

getUptime.sh
^^^^^^^^^^^^
Calculates and prints uptime in the form of ``Up: 6 years, 5 months, 18 days, 02:40:00``. Year/month info isn't shown if their value is 0. It's used by ``uptime=`` method in rtorrent.

Usage: ``getUptime.sh <<current_timestamp>> <<startup_timestamp>>``

queueTorrent.sh
^^^^^^^^^^^^^^^
Queue management script with rotating (deleting data) capability and category support (that can be included into a main script as well).

Usage: ``queueTorrent.sh`` or including in a main script: ``. "${BASH_SOURCE%/*}/queueTorrent.sh"``

reportMessages.sh
^^^^^^^^^^^^^^^^^
Send email report about any torrent with unusual tracker message.

Usage: ``reportMessages.sh``

reportOrphans.sh
^^^^^^^^^^^^^^^^
Send email report about any orphaned torrent.

Usage: ``reportOrphans.sh``

reportStopped.sh
^^^^^^^^^^^^^^^^
Send email report about any torrent that is stopped.

Usage: ``reportStopped.sh``

reportStuck.sh
^^^^^^^^^^^^^^
Send email report about any stuck torrent in incomplete directory.

Usage: ``reportStuck.sh``

rtUtils.sh
^^^^^^^^^^
General script with helper functions that can be included into main scripts.

Usage: including in a main script: ``. "${BASH_SOURCE%/*}/rtUtils.sh"``

sampleDownload.sh
^^^^^^^^^^^^^^^^^
Sample download script to demonstrate usage of inclusion of queue script inside a main script.

Usage: ``sampleDownload.sh``

rtorrent init script
^^^^^^^^^^^^^^^^^^^^
Init script. It can be installed and enabled by running: ``sudo update-rc.d rtorrent defaults 92`` and ``sudo update-rc.d rtorrent enable``.

Usage: ``sudo /etc/init.d/rtorrent [start|stop|restart|force-reload|status]``
