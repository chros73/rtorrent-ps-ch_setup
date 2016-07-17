## Some configuration on Windows

### Connect to Samba share

If we don't have a name server in our local network then an entry must be put in `C:\Windows\System32\drivers\etc\hosts`.

After that we can attach it with the following command:

```
net use U: \\ubuntu\wd3 /USER:chros73 foo /PERSISTENT:Yes
```

### Font linking on Windows

rTorrent-PS uses lot's of cool glyphs but unfortunately none of the fonts contained all of them on Windows.

As it turned out Windows has a feature called font linking to be able to set a fallback font if some characters are missing from the main one ([more info](https://github.com/pyroscope/rtorrent-ps/issues/8)).

I suggest to try out 2 fonts at first, DejaVu Sans Condensed will be our main font and Everson Mono as a fallback:

* DejaVu Sans Condensed from http://dejavu-fonts.org/wiki/Download
* Everson Mono from http://www.evertype.com/emono/

Install those fonts on Windows, then run the supplied registry patch: `fontlinking-dejavusanscondensed-eversonmono.reg`

I have tried out couple of fonts but DejaVu Sans Condensed was the only one which was good for me (with all of it's drawback, e.g. it's a variable-pitch font).
You can experiment with others (See Putty section).


### KiTTY configuration

Use [KiTTY](http://www.9bis.net/kitty/) version 0.67.x or greater (it's a patched [PuTTY](http://www.chiark.greenend.org.uk/~sgtatham/putty/) fork).

Advantages over `PuTTY`:
* fully portable
* auto reconnect on network failure
* [transparency of the window](http://www.9bis.net/kitty/?page=Transparency)

You have to [rename](http://www.9bis.net/kitty/?page=Download) the `exe` file to `putty.exe`.

The following settings are suggested for the session:
* Terminal:
    * uncheck "Use background colour to erase screen"
* Terminal - Features:
    * x "Disable remote-controlled terminal resizing"
* Window - Appearance:
    * x "Allow selection of variable-pitch fonts"
    * Font: DejaVu Sans Condensed, size: 9
* Window - Transparency:
    * Transparency: 20
* Window - Transparency:
    * Window title: `%%h - %%s`
* Window - Colours:
    * x "Allow terminal to use xterm 256-colour mode"
    * set "Indicate bolded text by changing" to " both"
* Connection:
    * x "Attempt to reconnect on system wakeup"
    * x "Attempt to reconnect on connection failure"
* Connection - Data:
    * set "Auto-login username" to your username
    * set "Terminal-type string" to "putty-256color"
* Connection - SSH - Auth:
    * set "Private key file for authentication" to point to your `ppk` file (that you generated previously)

Alternatively you can copy the supplied `KiTTY` directory that has almost all of these settings and it will create a session profile called `rtorrent-ps`.

This is how the final result look like, using solarized-blue theme:
![Extended Canvas Screenshot](https://raw.githubusercontent.com/chros73/rtorrent-ps/master/docs/_static/img/rTorrent-PS-CH-0.9.6-solarized-blue-kitty-s.png)
