Automated rTorrent-PS configuration
===================================

An almost completely automated setup with the patched version of rTorrent-PS, `rTorrent-PS-CH <https://github.com/chros73/rtorrent-ps/#fork-notes>`_ (requires v1.4-0.9.6 or newer) that doesn't need any additional UI only an SSH client (with the help of ``tmux``), including config files/scripts/instrucions for FTP, Samba, email reporting and many more.

.. figure:: https://raw.githubusercontent.com/chros73/rtorrent-ps/master/docs/_static/img/rTorrent-PS-CH-0.9.6-happy-pastel-kitty-s.png
   :align: center
   :alt: Extended Canvas Screenshot

.. contents:: **Contents**


Introduction
------------

It's all about seeding data all the time (unfortunately we have to download it before :) ) until we can. This is not the official ``pyroscope`` way to do things, I have to start with this. :) The project has been started around late 2014 with the curiosity of how many really useful things can be done with pure ``rtorrent``. As it turned out a lot.

The whole setup is based on an advanced version of the `Stefano's idea of download manager <http://www.stabellini.net/rtorrent-howto.txt>`_: it relies on moving data AND meta files all around the place. Please take the time and read more about this here: `#66 <https://github.com/chros73/rtorrent-ps_setup/issues/66>`_

It also includes some really unique ideas, so there's no need for ratio groups, stopping/starting torrents (either manually or by a script), deleting anything manually: it runs ``every`` torrent all the time, `favours one group of torrents over the rest of them <FavoringGroupOfTorrents.md>`_ and if it run out of space it'll try to create more by deleting old ones. These features make this setup sooo powerful! :)

This setup runs on a laptop from 2008 with dualcore CPU and 4GB of RAM with Ubuntu 14.04 (probably all other Debian flavor works fine, I don't know about the rest) and a 4TB HDD hooked up via ESATA with a net connection of 74/20 Mbps. It never stops until it gets power. :)

"Why is it just almost completely automated?" Well, because you, dear adventurer, have to figure out by yourself how to automate downloading of torrents.


Limitation
----------

"What?! Is there any?!" Well, yes. :) The following is not supported (mainly because of ``auto-rotating torrents`` feature in queue script and lack of interest :) ):

-  multiple disk device support (only 1 disk is supported) (read more: `#77 <https://github.com/chros73/rtorrent-ps_setup/issues/77>`_)


Features
--------

"OK, I can live with that, so what can it do?" Good question, let's see (most important ones come first):

-  downloading queue manager (read more: `#66 <https://github.com/chros73/rtorrent-ps_setup/issues/66>`_)
-  disk free space manager (read more: `#66 <https://github.com/chros73/rtorrent-ps_setup/issues/66>`_) : it's disabled by default (you have to enable it with ``AUTOROTATETORRENTS=true`` in queue script.)
-  favouring one group of torrents over the rest of them (read more: `FavoringGroupOfTorrents.md <FavoringGroupOfTorrents.md>`_)
-  hash-checking dropped data in ``incomplete`` dir and putting meta file into one the subdirs of ``.downloading`` dir
-  limited magnet link support (read more: `#74 <https://github.com/chros73/rtorrent-ps_setup/issues/74>`_)
-  regularly updates scrape information for all torrents (read more: `#5 <https://github.com/chros73/rtorrent-ps_setup/issues/5>`_)
-  sending email reports automatically
-  backup session dir of ``rtorrent``
-  auto-starting `rtorrent` in ``tmux`` if it's not running (with the help of an init script)
-  providing config files / instructions for setting up / using FTP , Samba, SSH
-  providing instructions for using it On-the-Road with an Android device
-  and a lot more :)


Useful additions in rtorrent
----------------------------

"Sounds awesome! What else?" There are extra stuff defined in ``rtorrent`` config files (half of them is created by ``pyroscope``):

-  `attributes <Additions.rst#extra-attributes-in-rtorrent-config-files>`_: ``unsafe_data``, ``data_dir``, ``meta_dir``, ``tm_downloaded``, ``tm_loaded``, ``tm_started``, ``tm_completed``, ``last_active``, ``activations``, ``tm_last_scrape`` 
-  `commands <Additions.rst#extra-commands-in-rtorrent-config-files>`_: ``d.move_to``, ``d.move_meta_to``, ``d.get_data_full_path``, ``d.remove_data``, ``d.add_to_delqueue``, ``d.remove_from_delqueue``, ``d.fix_delqueue_flag``, ``d.modify_slots_both``, ``d.last_scrape.send_set``, ``d.last_active``, ``uptime``, ``hrf_time``, ``i``, ``pyro.import``
-  `views <Additions.rst#extra-views-in-rtorrent>`_: ``^`` rtcontrol, ``!`` messages, ``t`` trackers, ``:`` tagged (``.`` toggle tag, ``T`` clear view), ``<`` datasize, ``>`` uploadeddata, ``%`` ratio, ``@`` category, ``?`` deletable
-  `keyboard shortcuts <Additions.rst#extra-keyboard-shortcuts-in-rtorrent>`_: ``*`` toggle collapsed/expanded display, ``#`` send manual scrape request, ``}`` toggle unsafe_data, ``|`` toggle selectable themes, ``=`` toggle autoscale network history, ``home``, ``end``, ``pgup``, ``pgdn``
-  `Bash functions <Additions.rst#extra-bash-functions>`_: ``rtlistOrphans``, ``rtlistStuck``, ``rtlistMessages``, ``rtlistStopped``
-  `Bash scripts <Additions.rst#extra-bash-scripts>`_: ``addMagnetLink.sh``, ``doBackup.sh``, ``getLimits.sh``, ``getUptime.sh``, ``queueTorrent.sh``, ``reportMessages.sh``, ``reportOrphans.sh``, ``reportStopped.sh``, ``reportStuck.sh``, ``rtUtils.sh``, ``sampleDownload.sh``, ``rtorrent init script``

See `Additions.rst <Additions.rst>`_ for more details.


Basic usage
-----------

"The whole thing is a little bit confusing now." Let's try to show how simple the workflow is:

-  download/upload/copy a torrent file into one the subdirs of ``.queue`` dir (the queue script will pick it)
-  alternatively put hash-checkable data into ``incomplete`` dir and put its meta file into one the subdirs of ``.downloading`` dir (hash-checking will start immediately)
-  when download/hash-check is finished data will be moved into it's final place
-  you can move it to a different category later using this command in ``rtorrent``: `d.move_to=unsafe,1,2 <Additions.rst#d-move-to-category-name-special-group-unsafe-data>`_
-  you can simply put it into delete queue by pressing `} <Additions.rst#extra-keyboard-shortcuts-in-rtorrent>`_ key multiple times
-  you can still delete a torrent manually if you insist by ``^d^d``

It's really that simple. :)


Hints and possible issues
-------------------------

See issue `#76 <https://github.com/chros73/rtorrent-ps_setup/issues/76>`_ for more details.


Migration
---------

"It's kind'a cool! The problem is that I have already a working setup. What shall I do?" It's easy:

-  make a backup first :)
-  set up everything according to the new setup
-  hash-ckeck all the existing data with the new setup (it will take care about everything else)

"Woow! But what about my previous local stats?" Well, nothing comes for free. :)


Installation
------------

"Okie, I kind'a like it. What should I do now?" Well, it won't be a 5 minutes task, but let's try to summarize it:

-  install `rTorrent-PS-CH <https://github.com/chros73/rtorrent-ps/#fork-notes>`_ (requires v1.4-0.9.6 or newer) and `pyrocore  <https://github.com/pyroscope/pyrocore>`_ utilities
-  go through all the files in this project and modify them according to your setup/needs
-  if you find a missing command on your system then install it (sorry I don't have a list of them)
-  check every command switch whether it's compatible with your system

"Oh, my ... That's a lot of work!" Well, it took way more time to create it and document it. :) Good news is: you only have to do it once. :)


Performance tuning
------------------

"Huhh, I finally managed to set it up, but what values should I use in rTorrent config?" Take a look at the  `official WIKI page <https://github.com/rakshasa/rtorrent/wiki/Performance-Tuning>`_.


Change log
----------

See `CHANGELOG.md <https://github.com/chros73/rtorrent-ps_setup/blob/master/CHANGELOG.md>`_ for more details.


Disclaimer
----------

Be careful! This setup ``can`` and ``will`` delete your data if you ask for it!

Only enable ``auto-rotating torrents`` feature in queue script (it's disabled by default) if you understand the basic concept of this setup and you configured everything as it should be!

This setup doesn't take any responsibility for data loss for any reason.


Acknowledgement
---------------

Thanks to the following people, sites:

-  `Rakshasa <https://github.com/rakshasa>`_ for this amazing `client <https://github.com/rakshasa/rtorrent>`_
-  `Pyroscope <https://github.com/pyroscope>`_ for his truly beautiful `rtorrent-ps patches <https://github.com/pyroscope/rtorrent-ps>`_ , `pyrocore utilities <https://github.com/pyroscope/pyrocore>`_ , `wiki of rutorrent <http://community.rutorrent.org/>`_ for useful examples
-  `archlinux rtorrent wiki <https://wiki.archlinux.org/index.php/RTorrent>`_ for useful examples and the idea of moving data and meta file of torrents
-  `the lost rtorrent docs <http://web.archive.org/web/20131209053932/http://libtorrent.rakshasa.no/wiki>`_ with the help of `web.archive.org <http://web.archive.org>`_
-  `Stefano <http://www.stabellini.net/rtorrent-howto.txt>`_ for the original idea of queue manager
-  anybody who has ever contributed in any way
