#!/usr/bin/perl

use strict;
use Math::Trig;

my $dim_r = 56.5;   # top-left 9-12 o'clock quadrant, centre is at (dim_r,0)
my $dim_lr = 54;
my $num_leds = 15;
my $inner_rad = 20;
my $hole_rad = 35;
my $led_pkg_width = 5;  # 4.699mm to pad edges, 0.301 = 11 mils 'grace'
my $debug = 1;

use constant PI => 4 * atan2(1, 1);

my $file = $ARGV[0] or die("Syntax:  thing.pl <infile>  > stuff\n");

open(FH, "< $file") || die("Can't open $file\n");

my $got_plain_section = 0;

my $line = 0;

sub outline_line {
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;
    print "<wire x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\" width=\"0\" layer=\"20\"/>\n";
}

sub print_outline {
    my $t;
    my $lx;
    my $ly;

    my $th = 0;
    $lx = $dim_lr - ($dim_r * cos($th));
    $ly = $dim_r * sin($th);

    my $bl_x = $lx;
    my $bl_y = $ly;
    
    for ($t = 0; $t < $num_leds + 1; $t = $t + 1) {
	my $nx, my $ny;
	$th = (PI/2)*($t)/$num_leds;
	$nx = $dim_lr - ($dim_r * cos($th));
	$ny = $dim_r * sin($th);
	outline_line($lx, $ly, $nx, $ny);
	$lx = $nx;
	$ly = $ny;
    }
    if ($inner_rad == 0) {
	# Furthest righermost x = $lx
	# Line from here, to y=$lb_y
	outline_line($lx,$ly, $lx, $bl_y);
	outline_line($lx, $bl_y, $bl_x, $bl_y);
    } else {
	outline_line($lx, $ly, $lx, $inner_rad);
	$ly = $inner_rad;
	for ($t = 0; $t <= 32; $t++) {
	    my $nx, my $ny;
	    $th = (PI/2)*(1 - ($t/32));
	    $nx = $dim_lr - ($inner_rad * cos($th));
	    $ny = $inner_rad * sin($th);
	    outline_line($lx, $ly, $nx, $ny);
	    $lx = $nx;
	    $ly = $ny;
	}
	outline_line($lx, $ly, $bl_x, $bl_y);
    }
}

sub get_hole_pos {
    my $x, my $y;

    my $th = (PI/4);
    $x = $dim_lr - ($hole_rad * cos($th));
    $y = $hole_rad * sin($th);
    return ($x, $y);
}

sub get_LED {
    my $led = shift;
    my $x, my $y, my $r;
    
    my $th = (PI/2)*($led - 1 + 0.5)/$num_leds;
    $x = $dim_lr - ($dim_lr * cos($th));
    $y = $dim_lr * sin($th);

    $r = 90 - (($led - 1 + 0.5) * (90/$num_leds));
    return ($x, $y, $r);
}

while (<FH>)
{
    my $print = 1;

    if (/\<plain\>/) {
	print STDERR "Found plain at line $line\n" if ($debug);
	$got_plain_section = 1;
    }
    if (/\<wire.*layer=\"20\"/) {
	$print = 0;
	if ($got_plain_section == 0) {
	    print "Wire layer 20 outside plain?  Line $line\n";
	}
    }
    if (/\<\/plain\>/) {
	print STDERR "Closed plain at line $line\n" if ($debug);
	# OK, closed plain section.  No more input outline.
	# Print out the board outline:
	print_outline();
    }
    # Remove silly attribute thing
    if (/attribute name="PROD_ID" value="DIO-09434"/) {
	s/\<attribute name="PROD_ID" value="DIO-09434".*\/\>/<!-- PROD_ID removed -->/;
    }

    # Look for LEDs & other things to move:

    if (/^(.*)(\<element name="D[0-9]*".*\>)(.*)$/) {
	my $before = $1;
	my $section = $2;
	my $after = $3;

	print $before;

	$section =~ /name="D([0-9]*)"/;
	my $led = $1;

	if ($led > 0 && $led < 16) {
	    print STDERR "Found LED $led\n";

	    # get, x, y, rot and substitute those tags in t="123" format
	    # if present-- rot may not be!
	    my $x, my $y, my $r;
	    ($x, $y, $r) = get_LED($led);
	    $section =~ s/x="[0-9.-]*"/x="$x"/;
	    $section =~ s/y="[0-9.-]*"/y="$y"/;
	    if ($section =~ /rot="[RL][0-9.-]*"/) {
		$section =~ s/rot="[RL][0-9.-]*"/rot="R$r"/;
	    } else {
		if ($section =~ /\<element name.*\/\>/) {
		    $section =~ s/\/\>/ rot="R$r"\/\>/;
		} elsif ($section =~ /\<element name.*[^\/]\>/) {
		    $section =~ s/\>/ rot="R$r"\>/;
		} else {
		    print STDERR "*** Odd tag terminator!\n";
		}
	    }
	    print $section."\n";

	    print $after;
	    # Don't print, we've already done it:
	    $print = 0;
	}
    } elsif (/^(.*)(\<element name="TDC".*\/\>)(.*)$/) {
	my $before = $1;
	my $section = $2;
	my $after = $3;

	print $before;

	print STDERR "Found hole\n";

	# get, x, y and substitute those tags in t="123" format
	my $x, my $y;
	($x, $y) = get_hole_pos();
	$section =~ s/x="[0-9.-]*"/x="$x"/;
	$section =~ s/y="[0-9.-]*"/y="$y"/;
	print $section."\n";

	print $after;
	# Don't print, we've already done it:
	$print = 0;
    }

    print if ($print);
    $line++;
}
