#!/usr/bin/perl -w
# Author: Massimo Lamanna (Massimo.Lamanna@cern.ch) 1998-99
# $Id: bkm_dir.pl,v 1.2 2001/06/01 14:16:20 laman Exp $ 

require 5.004;

use strict;
use diagnostics;

# Input 1: $mode      (quiet/verbose)
# Input 2: $setupFile (existing readable file)

sub bkm_dir {

    my(@bkm_dir);
    my(%bkm_entry)=();

# Check input

    my($mode) =  $_[0];
    my($setupFile) = $_[1];
#   print "$mode\n";
#   print "$setupFile\n";

    defined $mode || die "$0: Undefined mode";
    defined $setupFile || die "$0: Undefined setup file";

    $mode eq "-verbose" || $mode eq "-quiet" || die "$0: Invalid mode $mode";
    (-r $setupFile) || die "$0: Cannot access $setupFile";

# Open setup file
    
    open (IN,$setupFile) || die "$0: cannot open $setupFile for reading: $!";
    my($string);

    my($bkm_dir);

    while(<IN>) {

	if(/(^BKM )/) {
		$bkm_dir = $_;

		$bkm_dir =~ s/BKM//;
		my($bkm_host) = $bkm_dir;
	    
		$bkm_dir =~ s/(\w)+\s//;
		$bkm_dir =~ s/\s//g;
	    
		$bkm_host =~ /(\w)+\s/;
		$bkm_host = $&;
		$bkm_host =~ s/\s//g;
		
# 		$mode eq "-verbose" && print "BKM list: host $bkm_host $bkm_dir\n";
		$bkm_dir =~ /\/merger\// # It was data in the compass setup 
		    || $bkm_dir =~ /\/shift\// 
			|| $bkm_dir =~ /\/tmp\// 
			    || die "$0: Invalid format!\n";
# 		$bkm_dir =~ /$bkm_host/ || die "$0: Invalid format!\n";
	    
#		print "BKM list: host $bkm_host $bkm_dir\n";
		push @bkm_dir,$bkm_dir;
                $bkm_entry{$bkm_host} = $bkm_dir;
	    
	}

    }
    
    close (IN);
    
    defined($bkm_dir) || die "$0: Invalid setup file $setupFile: no BKM dir defined";
        
#    return (@bkm_dir);
    return %bkm_entry;

}
