## Some configuration on Windows

**Contents**

 * [Connect to Samba share](#connect-to-samba-share)
 * [Connect via FTP](#connect-via-ftp)
 * [Font linking on Windows](#font-linking-on-windows)
 * [Connect via SSH](#connect-via-ssh)

### Connect to Samba share

If we don't have a name server in our local network then an entry must be put in `C:\Windows\System32\drivers\etc\hosts` for our Ubuntu machine. See [hosts file](https://github.com/chros73/rtorrent-ps-ch_setup/blob/master/windows-8.1/C/Windows/System32/drivers/etc/hosts) for an example.

After that we can map the drive from Windows Explorer (Windows forgot the password upon reboot using command line version of attaching shares from Ubuntu):
* set drive: `U:` , share: `\\ubuntu\wd3`
* check the boxes for `Reconnect at sign-in` and `Connect using different credentials`
* user: `chrosGX620lan\chros73` , pass: `foo` , check `Remember credentials`


### Connect via FTP

[FileZilla](https://filezilla-project.org/download.php) is a pretty flexible, opensource FTP client and it's available for every major OS. More importantly it supports [TLS](https://wiki.filezilla-project.org/FTP_over_TLS) authentication.

The following settings under `Site Manager` are suggested for the session:
* set `Host`, `Port`
* Protocol: `FTP - File Transfer protocol`
* Encryption: `Use explicit FTP over TLS if available`
* set `User`, `Password`


### Font linking on Windows

`rTorrent-PS` uses lot's of cool glyphs but unfortunately none of the fonts contained all of them on Windows.

As it turned out Windows has a feature called font linking to be able to set a fallback font if some characters are missing from the main one ([more info](https://github.com/pyroscope/rtorrent-ps/issues/8)).

I suggest to try out 2 fonts at first, `DejaVu Sans Condensed` will be our main font and `Everson Mono` as a fallback:

* `DejaVu Sans Condensed` from https://dejavu-fonts.github.io/
* `Everson Mono` from http://www.evertype.com/emono/

Install those fonts on Windows, then run the supplied registry patch: [fontlinking-dejavusanscondensed-eversonmono.reg](https://github.com/chros73/rtorrent-ps-ch_setup/blob/master/windows-8.1/fontlinking-dejavusanscondensed-eversonmono.reg)

I have tried out couple of fonts but `DejaVu Sans Condensed` was the only one which was good for me (with all of it's drawback, e.g. it's a variable-pitch font).
You can experiment with others (see Connect via SSH section).


### Connect via SSH

Use [KiTTY](http://www.9bis.net/kitty/) version 0.70.0.1p or greater (it's a patched [PuTTY](http://www.chiark.greenend.org.uk/~sgtatham/putty/) fork).

Advantages over `PuTTY`:
* fully portable
* auto reconnect on network failure
* [transparency of the window](http://www.9bis.net/kitty/?page=Transparency)

You have to [rename](http://www.9bis.net/kitty/?page=Download) the `exe` file to `putty.exe`.

The following settings are suggested for the session:
* Terminal - Features:
    * check `Disable remote-controlled terminal resizing`
* Window - Appearance:
    * check `Allow selection of variable-pitch fonts`
    * Font: `DejaVu Sans Condensed`, size: `9`
* Window - Transparency:
    * Transparency: `20`
* Window - Transparency:
    * Window title: `%%h - %%s`
* Window - Colours:
    * check `Allow terminal to use xterm 256-colour mode`
    * Indicate bolded text by changing: `both`
* Connection:
    * check `Attempt to reconnect on system wakeup`
    * check `Attempt to reconnect on connection failure`
* Connection - Data:
    * Auto-login username: `your-username`
    * Terminal-type string: `putty-256color`
* Connection - SSH - Auth:
    * Private key file for authentication: set it to point to your `ppk` file (that you generated previously)

Alternatively you can copy the supplied [KiTTY directory](https://github.com/chros73/rtorrent-ps-ch_setup/tree/master/windows-8.1/KiTTY) that has almost all of these settings and it will create a session profile called `rtorrent-ps`.

This is how the final result look like, using solarized-blue theme:
![Extended Canvas Screenshot](https://raw.githubusercontent.com/chros73/rtorrent-ps-ch/master/docs/_static/img/rTorrent-PS-CH-solarized-blue-kitty-s.png)
