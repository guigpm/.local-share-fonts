# W11 Fonts for Linux

Tested in Linux **Mint** and **ZorinOS**!

## Installation

Just create a `.fonts` or `.local/share/fonts` folder in your home directory (if it doesn't exist) and unpack/copy them there.

### I don't know where to install my fonts!

No problem. This command will give us the list of valid directories:
```bash
$ fc-cache -v -f 2>&1 | awk '/Font directories:/ {p=1; next} /^\// {p=0} p {print}' | sed 's/^[ \t]*//'
```

*   `fc-cache -v -f`: Runs the font cache utility in verbose mode (`-v`) and forces a full regeneration (`-f`) of all font directories.
*   `2>&1`: Redirects the standard error (stderr) to the standard output (stdout), ensuring all status logs are captured by the pipe.
*   `|`: The pipe operator redirects the output text from the command on the left to serve as the input for the command on the right.
*   `awk '...'`: A text processing tool used here to target, isolate, and capture only the lines containing the directory paths.
*   `/Font directories:/ {p=1; next}`: Tells `awk` to locate the main header line and start capturing (`p=1`) everything right after it.
*   `/^\// {p=0}`: Instructs `awk` to stop capturing (`p=0`) as soon as it hits a line starting with a forward slash (`/`), which marks the end of the initial list.
*   `p {print}`: Passes the text of all allowed lines forward while the capturing flag remains active.
*   `sed 's/^[ \t]*//'`: Uses a stream editor to strip away any leading spaces or tabs (`\t`) from the beginning of each line, leaving only the clean directory paths.

---

### For `/home/USERNAME/.local/share/fonts` folder:

Change "USERNAME" to your username on the machine.

```bash
$ mkdir -p /home/USERNAME/.local/share/
```
OR
```bash
$ mkdir -p ~/.local/share/
```

Clone into /home/USERNAME/.local/share/fonts:

```bash
$ sudo apt install git ttf-mscorefonts-installer
```

```bash
$ git clone https://github.com/guigpm/.local-share-fonts.git /home/USERNAME/.local/share/fonts
```
OR
```bash
$ git clone https://github.com/guigpm/.local-share-fonts.git ~/.local/share/fonts
```

---

### For `/home/USERNAME/.fonts` folder:

Change "USERNAME" to your username on the machine.

Clone into /home/USERNAME/.fonts:

```bash
$ sudo apt install git ttf-mscorefonts-installer
```

```bash
$ git clone https://github.com/guigpm/.local-share-fonts.git /home/USERNAME/.fonts
```
OR
```bash
$ git clone https://github.com/guigpm/.local-share-fonts.git ~/.fonts
```

---

### Update the system font cache

For the system and applications to recognize the new fonts immediately, update the Fontconfig cache:

```bash
$ fc-cache -f -v
```

*   `-f`: Forces the regeneration of cache files (reconstructs the cache).
*   `-v`: Displays status messages on the screen (verbose mode), allowing you to confirm that the user directory was successfully scanned.

### (Optional) Verify if the font was installed
To ensure the installation was successful, you can list the system fonts and filter by the name of your installed font:

```bash
$ fc-list : family | grep -i "FontName"
```
