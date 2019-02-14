UAE based Amiga virus scanner for POSIX
========================================


What is this contraption?
--------------------------

A command line based Amiga virus scanner for Linux and similar systems.

Usage:

Either of

    ./amiga-uae-virus-scan.sh floppy-to-test.adf

or

    ./amiga-uae-virus-scan.sh directory-to-scan


What this can, and cannot scan
-------------------------------

Anything that CheckX, XAD, and XFD understand.

This includes entire ADF files.
However note that floppy images will be exposed to CheckX
as *files* rather than be mounted, thus rendering it
incapable of e.g. scanning IPF files.

This script will scan only one element at a time, but that
can be an entire folder structure.


If you wish to scan raw floppies in strange image formats
which are understood by FS-UAE, but not by CheckX, then
change the script to mount the image as `DF1:`
(see `write_uae_config()`), and to have it scan that drive
rather than a folder structure (see `populate_dh0()`).


Theory of operation
--------------------

This is a script that:

 - prepares a virtual Amiga hard drive,
 - installs a virus scanner onto it,
 - copies the files to be scanned onto it,
 - runs FS-UAE,
 - and finally prints the results to stdout.

If you abort the process by pressing Ctrl+C, there will be
stale files in /tmp.


Libraries used
---------------

This script makes use of the following tools and libraries:

 - CheckX - the virus scanner
 - xvs.library - virus signature collection
 - xadmaster.library - archive unpacker (`.lha`, `.adf`, ...)
 - xfdmaster.library - decruncher (for packed executables, ...)
 - UAEquit - to shut down the emulator when done.


Dependencies
-------------

The script will automatically download several archives from
Aminet unless they have already been cached locally.

See `installer_urls` for details.

It requires the following tools to be installed on the host:

    curl
    lha
    fs-uae
    sha256sum


Security
---------

The files downloaded from Aminet are checked against local
SHA-256 checksums.

Files to be analyzed are copied into the virtual system first,
to ensure that we do not have to grant it access to host files.
Thus, even if something exploits a security issue in the Amiga
virus scanner, it won't be able to break the host unless it
also breaks FS-UAE.


Comparison to similar tools
----------------------------

- ADFscan: The original inspiration for this project.
  This is a Visual Basic application scanning for only a
  handful of the most common signatures. It has its own
  unpacker for Amiga OFS to be able to scan ADFs.

  + amiga-uae-virus-scan uses well-known Amiga libraries and
    tools to perform these tasks, allowing it to detect more
    viruses and unpack more formats, by order(s) of magnitude.



Thanks
=======

Acknowledgements go out to the authors of the software used,
as well as to Aminet for hosting it.

Thanks also to the UAE authors, and of course to the AROS
kickstart hackers.

This would not be possible without you.



License
========

GNU General Public License v2 only.
