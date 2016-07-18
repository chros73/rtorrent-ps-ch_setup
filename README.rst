Automated rTorrent-PS configuration
===================================

An almost completely automated setup with the patched version of rTorrent-PS, `rTorrent-PS-CH <https://github.com/chros73/rtorrent-ps/#fork-notes>`_, including config files/scripts/instrucions for FTP, Samba, email reporting and many more.

.. figure:: https://raw.githubusercontent.com/chros73/rtorrent-ps/master/docs/_static/img/rTorrent-PS-CH-0.9.6-happy-pastel-kitty-s.png
   :align: center
   :alt: Extended Canvas Screenshot

.. contents:: **Contents**


Introduction
------------

This is not the official ``pyroscope`` way, I have to start with this. :)


Limitation
----------

Support for the following are missing (mainly because of ``auto-rotating torrents`` feature in queue script):

-  handling of magnet links
-  multiple disk device support (only 1 disk is supported)


Features
--------




Basic usage
-----------




Change log
----------

See `CHANGELOG.md <https://github.com/chros73/rtorrent-ps_setup/blob/master/CHANGELOG.md>`_ for more details.


Disclaimer
----------

Be careful! This setup ``can`` delete your data!

Only enable ``auto-rotating torrents`` feature in queue script (it's disabled by default) if you understand the basic concept of this setup and you configured everything as it should be!

This setup deosn't take any responsibility for data loss for any reason.


Acknowledgement
---------------

Thanks to the following people, sites:

-  `Rakshasa <https://github.com/rakshasa>`_ for this amazing `client <https://github.com/rakshasa/rtorrent>`_
-  `Pyroscope <https://github.com/pyroscope>`_ for his truly beautiful `rtorrent-ps patches <https://github.com/pyroscope/rtorrent-ps>`_ , `pyrocore utilities <https://github.com/pyroscope/pyrocore>`_ , `wiki of rutorrent <http://community.rutorrent.org/>`_ for useful examples
-  `archlinux rtorrent wiki <https://wiki.archlinux.org/index.php/RTorrent>`_ for useful examples and the idea of moving data and meta file of torrents
-  `the lost rtorrent docs <http://web.archive.org/web/20131209053932/http://libtorrent.rakshasa.no/wiki>`_ with the help of `web.archive.org <http://web.archive.org>`_
-  `Stefano <http://www.stabellini.net/rtorrent-howto.txt>`_ for the idea of queue manager
-  anybody who have ever contributed in any way
