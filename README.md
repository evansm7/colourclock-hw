RGB Colourclock hardware design
===============================

19th March 2018

My Colourclock is a circular wall clock with 60 RGB LEDs.  See <http://www.axio.ms/projects/2018/03/19/Colourclock.html> for information/pictures, and <http://github.com/evansm7/colourclock-fw> for firmware.

This repository contains:

*    Eagle schematic and board files
*    A simple BOM
*    Assembly jig diagram
*    Perl script to automatically create the outline of a single PCB, which is one quarter of a ring of PCBs.  The script also places the 15 RGB LED footprints at the correct locations.

This will hopefully serve as an example for similar designs, and show you how to automate PCB creation using Eagle .brd files (>= version 6).  The workflow was roughly as follows:

*    Create the schematic
*    Create a basic .brd file with instances of LEDs D1 to D15
*    Run this .brd file through the ```mkboard.pl ``` script
*    Tweak the parameters until the size/placement/spacing looks good.

It's possible to change the board outline even after you've routed most of it (and have run out of space...).

* * *

These files are copyright (c) 2014 Matt Evans.  You are permitted to make use of these designs for non-commercial or educational purposes.

