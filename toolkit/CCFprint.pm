#!/usr/bin/perl -w
#
# CCF print utilities
# 
# Author: Massimo Lamanna (Massimo.Lamanna@cern.ch) 1998-99
# $Id: CCFprint.pm,v 1.4 2002/06/12 10:12:08 objsrvvy Exp $ 
#
#
# dot60 = sleep 60 s and print a dot; \n every hour
# infoPrint = to be used as startup message in jobs:
#             print file name and date
#

package CCFprint;

use Exporter;

@ISA = (Exporter);
@EXPORT = qw(dot60 dot300 dot600 dot3600 infoPrint);
@EXPORT_OK = qw();

# Startup message for scripts (script name + date)
sub infoPrint {

    my $script = (caller(0))[1];

    $date = `date`;
    print "$script: $date";

    return;

}

# Sleep 60 seconds
sub dot60 {

    $dotcounter++;
# New line every 60 dots
    if($dotcounter>60) {
	$dotcounter = 0;
	print "\n";
    }
    print ".";
    sleep(60);
    return;

}

# Sleep 600 seconds
sub dot600 {

    $dotcounter++;
# New line every 60 dots
    if($dotcounter>60) {
	$dotcounter = 0;
	print "\n";
    }
    print "*";
    sleep(600);
    return;

}
# Sleep 300 seconds
sub dot300 {

    $dotcounter++;
# New line every 60 dots
    if($dotcounter>60) {
	$dotcounter = 0;
	print "\n";
    }
    print "+";
    sleep(300);
    return;

}

# Sleep 1 hours
sub dot3600 {

    $dotcounter++;
# New line every 60 dots
    if($dotcounter>60) {
	$dotcounter = 0;
	print "\n";
    }
    print "o";
    sleep(3600);
    return;

}

1;
