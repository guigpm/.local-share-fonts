# .fonts for Linux

Tested in Linux Mint!

## Installation

Just create a .fonts folder in your home directory (if it doesn't exist) and unpack/copy them there.

Clone into /home/username:

    $ sudo apt install git ttf-mscorefonts-installer
    $ git clone https://github.com/guigpm/.local-share-fonts.git /home/USERNAME/.local/share/fonts

Change "username" to your username on the machine.

It's also a good idea to manually rebuild the font cache, so you can immediately use the fonts everywhere:

    $ fc-cache -f -v

