# XRoar - RetroDECK Mirror
This repository is automatically cloning and building XRoar Linux versions from the official website.
Albeit this is intended to be used on RetroDECK, feel free to grab this binaries as are clean builds.

Official project website:
https://www.6809.org.uk/xroar/

# Original README
XRoar - a Dragon and Tandy 8-bit computer emulator
Copyright 2003-2025 Ciaran Anscomb <xroar@6809.org.uk>


Introduction
************

XRoar emulates the Dragon 32/64; Tandy Colour Computers 1, 2 and 3; the
Tandy MC-10; and some other similar machines or clones.  It runs on a
wide variety of platforms.  Emulated hardware includes:

   * Dragon 32, 64, and 200-E; Tandy CoCo 1, 2, & 3; Tandy MC-10; Matra
     & Hachette Alice 4K.
   * Dragon Professional and Tandy Deluxe Colour Computer prototypes,
     both including the AY-3-891x sound chip.
   * DragonDOS, Delta and RS-DOS floppy disk controller cartridges.
   * Orchestra 90-CC stereo sound cartridge.
   * Games Master Cartridge, including the SN76489 sound chip.
   * Glenside IDE cartridge, with IDE hard disk image support.
   * NX32 and MOOH RAM expansions, with SPI and SD card image support.

   Other features include:

   * Raw and translated keyboard modes.
   * Read and write cassette tape images.
   * Read and write floppy disk images.
   * Becker port for communication with remote servers.
   * Save and load machine snapshots.
   * GDB target for remote debugging.

   XRoar is easily built from source under Linux, and binary packages
are provided for Windows and Mac OS X+.

   XRoar can also be compiled to WebAssembly, and redistributing it in
this form may provide a convenient way for users to run your Dragon
software.  See XRoar Online (https://www.6809.org.uk/xroar/online/) for
an example.

   XRoar is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

   XRoar is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

   You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

   This README contains extracts from the manual.  Binary packages
contain the full manual as a PDF, which is also available from the XRoar
home page (https://www.6809.org.uk/xroar/).

Recent changes
==============

Changes in version 1.8 include:

   * HD mounting from drive control dialog.
   * New MCX128 cartridge support for MC-10.
   * CoCo 3 GIME behaviour fixes.
   * CoCo 3 Monitor detect line asserted when RGB TV input selected.
   * Becker port latency fixes.
   * More flexible command-line trap options.

   Previous changes in 1.x include:

   *Important:* Floppy disk write-back is now _enabled_ by default.
Writes to images held in memory will overwrite the on-disk file when
ejected (or quitting XRoar).  You can get the old file-preserving
default behaviour back with '-no-disk-write-back'.

   Gamepad mapping files can provide more consistent button layouts.

   RAM organisation selection with '-ram-org', and initialisation
pattern selection with '-ram-init'.

   The '-ccr simulated' renderer is replaced with more CPU-intensive
code that also handles PAL. The old NTSC-only renderer is still
available using '-ccr partial'.

   Larger or smaller picture area can be selected, and XRoar can stretch
60Hz output to reproduce the apparent aspect ratio seen on CRTs in those
countries.

   Many video options can be changed on the fly in a new TV Controls
dialog.

   Screenshots in PNG format can be saved if XRoar is built with libpng.

   More machines are emulated than in 0.x.  A new snapshot format that
preserves more state was required to support these.  Old snapshots
should still load for now, though this will likely be removed in time.

   Tape emulation now supports manual pause control, required for using
the MC-10 & Alice, as they have no remote tape motor control.

   HD/SD images are now specified with '-load-hd0' and '-load-hd1'.  IDE
images with a header should be distinguished from headerless files by
giving them a '.ide' extension.

   MPI slot configuration is now per-cart rather than global.

Getting started
***************

Prerequisites
=============

To run XRoar, you will need to make sure you have the firmware ROM
images available for the system you wish to emulate.  These images can
be transferred from your original machine (with some effort, outside the
scope of this document) or more likely found online on one of the
archive websites.  Where XRoar looks to find these images depends on
your host OS; the rest of this chapter will go into detail.

   Firmware ROM image files should have a '.rom' extension, and be
headerless (so their file size will be an exact power of two bytes).
For most use cases, you'll need the BASIC ROM image(s) and a disk
controller ROM image.  Here are the expected filenames and sizes (in
bytes) for some of the most commonly-required images:

Firmware ROM                      Filename         File size
-----------------------------------------------------------------------
Dragon 32 BASIC                   'd32.rom'        16384
Dragon 64 32K BASIC               'd64_1.rom'      16384
Dragon 64 64K BASIC               'd64_2.rom'      16384
DragonDOS                         'ddos10.rom'     8192
Tandy Colour BASIC                'bas13.rom'      8192
Tandy Extended BASIC              'extbas11.rom'   8192
Tandy Super ECB (CoCo 3)          'coco3.rom'      32768
Tandy Super ECB (PAL CoCo 3)      'coco3p.rom'     32768
Tandy RS-DOS                      'disk11.rom'     8192
Tandy Microcolour BASIC (MC-10)   'mc10.rom'       8192

   Other machines (e.g.  the less common Dragon 200-E) will need a
different set of ROM images, and supported peripherals may also need
their own firmware.

Getting started under Linux/Unix
================================

If you configure a suitable Apt repository under Debian or Ubuntu, you
should simply be able to 'apt install xroar' (as root, or using 'sudo').
See the XRoar homepage (https://www.6809.org.uk/xroar/) for links to an
Apt repository for Debian, or to Launchpad for Ubuntu.

   Otherwise, if you are comfortable building from source, see *note
Building from source::.

   In your home directory, create directories '~/.xroar/' and
'~/.xroar/roms/':

     $ mkdir -p ~/.xroar/roms

   Copy your firmware ROM images (*note Prerequisites::) into
'~/.xroar/roms/'.  For example, covering the most common machines, you
might end up with a directory looking like this:

     $ ls -l ~/.xroar/roms/
     [...]
     -rw-r--r-- 1 user group  8192 Jan  1  1982 bas13.rom
     -rw-r--r-- 1 user group 32768 Jul 30  1986 coco3.rom
     -rw-r--r-- 1 user group 32768 Jul 30  1986 coco3p.rom
     -rw-r--r-- 1 user group 16384 Aug  1  1982 d32.rom
     -rw-r--r-- 1 user group 16384 Aug  1  1983 d64_1.rom
     -rw-r--r-- 1 user group 16384 Aug  1  1983 d64_2.rom
     -rw-r--r-- 1 user group  8192 Jun  1  1983 ddos10.rom
     -rw-r--r-- 1 user group  8192 Jan  1  1982 disk11.rom
     -rw-r--r-- 1 user group  8192 Jan  1  1982 extbas11.rom
     -rw-r--r-- 1 user group  8192 Oct  1  1983 mc10.rom

   Start the emulator by typing 'xroar' at the command line, or by
selecting it from Applications -> Games if your environment provides an
applications menu.

   Running 'xroar --help' will display the supported command line
options.  Each of the command line options can also appear in a
configuration file, which should be called '~/.xroar/xroar.conf'.  You
can configure many defaults and even extra machines and cartridges in
this file.  See *note Configuring XRoar:: for more details.

Getting started under Windows
=============================

The simplest way to get going under Windows is to unpack the '.zip' file
and copy all your ROM images into the created subdirectory, alongside
the executable.  You can also create a configuration file here called
'xroar.conf'.  Double click 'xroar.exe' to run, and XRoar will look in
the same directory that you start it from, and everything should work.

   However, if you want a more organised installation where you don't
have to re-copy files around every time you upgrade, read on.

   In your user profile, there should exist a LocalAppData directory.
This is something Windows calls a "Known Folder".  You should be able to
browse to it by entering '%LOCALAPPDATA%' as a path in an explorer
window.  (1)

   Under '%LOCALAPPDATA%', create a subdirectory called 'XRoar'.  Then
within _that_, create a further subdirectory named 'roms'.  You can then
copy your ROM images into '%LOCALAPPDATA%\XRoar\roms\'.

   Start the emulator by double clicking 'xroar.exe' or, if you
installed the '.msi', by selecting XRoar from the start menu.

   You can also run XRoar from the command line, and it supports the
same options as under Linux/Unix.  By default GUI applications under
Windows have no access to a console, so run XRoar with '-C' as the very
first option and it will first try to attach to the console of the
parent process--that is, send text output to the shell window you have
open--and if that fails, it will create its own console window.  This
lets you see various notifications that can be useful when determining
why something isn't working the way you expect.

   For example, run 'xroar.exe -C --help' to display a list of the
supported command line options.  Each of the command line options can
also appear in a configuration file, which should be called
'%LOCALAPPDATA%\XRoar\xroar.conf'.  You can configure many defaults and
even extra machines and cartridges in this file.  See *note Configuring
XRoar:: for more details.

   ---------- Footnotes ----------

   (1) The reason for using the _local_ version version of the AppData
directory under Windows is that recent versions of Windows may offload
files in other places to the cloud--I'm told this can happen without it
ever informing the user--and we want to keep files local to the machine,
as cloud access may require specific application support.

Getting started under Mac OS X+
===============================

Download and unzip the appropriate '.zip' distribution for your system.
Drag the application icon to '/Applications/'.

   ROM images should be placed in a directory you create named
'~/Library/XRoar/roms/' (under your 'HOME' directory, not the system
directory, '/Library/').

   The Mac OS X+ build provides a menu for access to certain features,
and often accepts the more familiar '<Command>+KEY' in place of the
'<CTRL>+KEY' shortcuts listed in this manual.  It does not provide
control dialog boxes; often, options in these dialogs will instead be
found in the menu hierarchy.

   For troubleshooting or testing options, it's often a good idea to run
from the command line, but application packages don't make that trivial.
A symbolic link to somewhere in your 'PATH' is all that's required.
e.g.:

     $ sudo ln -s /Applications/XRoar.app/Contents/MacOS/xroar \
             /usr/local/bin/xroar

   After this, you can start the emulator by simply typing 'xroar'
followed by any command line options.

   For example, run 'xroar --help' to display a list of the supported
command line options.  Each of the command line options can also appear
in a configuration file, which should be called
'~/Library/XRoar/xroar.conf' (under your 'HOME' directory).  You can
configure many defaults and even extra machines and cartridges in this
file.  See *note Configuring XRoar:: for more details.

Building from source
====================

It is straightforward to build XRoar from source on any Unix-like OS so
long as you have the normal build tools installed, and satisfy a few
dependencies.

   The binary packages for Windows are cross-compiled under Linux using
MinGW; it may be possible to build natively using something like MSYS2
or Cygwin, but this is untested.

   XRoar depends on external libraries for most aspects of its user
interface:

   * GTK+ 3 (https://www.gtk.org/) is recommended, and provides video,
     menus, and dialogs.  It may be possible to use GTK+ under Mac OS
     X+, but this is untested.  GTK+ 2 is deprecated, but still usable
     if you also have GtkGLExt installed.

   * SDL 2 (https://libsdl.org/) provides a simpler interface, but extra
     code for Mac OS X+ adds some basic menus and file requester
     dialogs.  For non-Linux systems, it may also be the easiest way to
     get support for joysticks and audio.

   * PulseAudio or ALSA can also be used for audio support.  Older code
     still exists for OSS and Jack, but these have not been tested for a
     while.

   * libpng (http://www.libpng.org/pub/png/libpng.html) is recommended,
     and allows the saving of screenshots in PNG format.

   Under Debian, these dependencies can be satisfied with this simple
invocation of Apt:

     $ sudo apt install build-essential libgtk-3-dev \
                        libpulse-dev libpng-dev

   XRoar uses the GNU Build System (Autotools), so the compilation
process should be very familiar.  The following process compiles XRoar
and installs it into '/usr/local', like most other software built this
way:

     $ gzip -dc xroar-1.8.2.tar.gz | tar xvf -
     $ cd xroar-1.8.2
     $ ./configure
     $ make
     $ sudo make install

   If you have cloned the git repository, you will also need GNU Build
System packages installed ('autoconf', etc.)  Running './autogen.sh'
should then generate the configure script, which you can then run as
normal.

   The 'configure' script has a lot of options guiding what it tests
for, specifying cross-compilation, changing the install path, etc.  List
them all with the '--help' option.
