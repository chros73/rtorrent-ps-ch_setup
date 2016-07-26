## On-the-Road configuration using free apps on Android

**Contents**

 * [Connect via SSH](#connect-via-ssh)
 * [Connect via FTP](#connect-via-ftp)
 * [Connect to Samba share](#connect-to-samba-share)

### Connect via SSH

[JuiceSSH](https://juicessh.com) is a really easily configurable and usable SSH client with `tmux`. Although it has some rendering bugs regarding to Unicode characters, as we can see below, it's still amazing.
![Extended Canvas Screenshot in JuiceSSH](https://github.com/chros73/rtorrent-ps/blob/master/docs/_static/img/rTorrent-PS-CH-0.9.6-happy-pastel-juicessh-s.png)

The following settings under `Settings` are suggested for the session:
* set "Theme / Colours" to `Solarized Dark`
* set "Font size" to `9`
* set "Horizontal Swipe" to `Screen next/prev window` (since our `tmux` config has rebinded keys)
* enable "UTF-8" support
* set "Emulator Type" to `xterm-256color`

Set up new connections under `Connections`:
* create new identity under `Identities` tab (it has to be transported to the Ubuntu machine)
* create new connection under `Connections` tab for external use
   * set "Nickname", "Address", "Port"
   * select the previously generated identity for "Identity"
* duplicate the previously created connection under `Connections` tab for internal use
   * modify "Nickname", "Address", "Port"


### Connect via FTP

[FTP Express](https://play.google.com/store/apps/details?id=com.zifero.ftpclient) ([homepage](https://www.zifero.com/apps/ftp-express/)) is the only FTP client (that I've tried) that actually can authenticate over `TLS` (many FTP client apps state that they can :) ).

Set up new connection under `Sites` tab using `+` sign:
* set "Name", "Host", "Port"
* select `FTPS explicit` for "Protocol"
* set "User", "Password"
* set "Remote" to `/Torrents/.rtorrent/.queue` (to be able to easily transfer files into one of the category directories of queue directory)
* x "Passive Mode"
* select `UTF-8` for "Character Encoding"

You can duplicate the previously created connection if you like for internal use:
* modify "Name", "Host", "Port"


### Connect to Samba share

[ES File Explorer](http://www.estrongs.com) can be used for accessing `Samba shares` within our local network as well. Once it accessed to a share then a selected file can be `Open with` by any application (it has a role as a middle layer).

Set up new share under `Network` tab using `New` command in `|` at top right:
* set "Server" to "ip/sharename", e.g. `192.168.1.8/wd3`
* set "Username", "Password"
* set a "Display name"

That's it, it should work. If not and you are sure that it should (e.g. there's no firewall blocking, etc.) then ping the IP of the Ubuntu machine from a terminal app (I'm not kidding :) ) and try to connect to it again.
