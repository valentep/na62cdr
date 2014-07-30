#!/usr/bin/perl -w
# Author: Massimo Lamanna (Massimo.Lamanna@cern.ch) June 2000
# $Id: decode_fdb.pl,v 1.4 2001/06/05 16:10:23 laman Exp $

require 5.004;

use strict;
use diagnostics;

# Input 1: $mode      (quiet/verbose)
# Input 2: $setupFile (existing readable file)



sub getOption {

# Check input

    my($mode)      = $_[0];
    my($setupFile) = $_[1];
    my($key)       = $_[2];

#   print "$mode\n";
#   print "$setupFile\n";
#   print "$key\n";

    defined $mode || die "$0: Undefined mode";
    defined $setupFile || die "$0: Undefined setup file";

    $mode eq "-verbose" || $mode eq "-quiet" || die "$0: Invalid mode $mode";
    (-r $setupFile) || die "$0: Cannot access $setupFile";

# Open setup file
    
    open (IN,$setupFile) || die "$0: cannot open $setupFile for reading: $!";
    my($string);
    my($n);

    while(<IN>) {

	if(/($key )/) {
	    $n = $_;
		
	    $n =~ s/$key//;
	    $n =~ s/\s//g;
	    chomp($n);
	    
	    $mode eq "-verbose" && print "$key: $n\n";
	}
	
    }
    
    close (IN);
    
    defined($n) || ($n=0);
        
    return ($n);

}


sub getOptionHost {

# Check input

    my($mode)      = $_[0];
    my($setupFile) = $_[1];
    my($key)       = $_[2];
    my($host) = getHost();

#   print "$mode\n";
#   print "$setupFile\n";
#   print "$key\n";

    defined $mode || die "$0: Undefined mode";
    defined $setupFile || die "$0: Undefined setup file";

    $mode eq "-verbose" || $mode eq "-quiet" || die "$0: Invalid mode $mode";
    (-r $setupFile) || die "$0: Cannot access $setupFile";

# Open setup file
    
    open (IN,$setupFile) || die "$0: cannot open $setupFile for reading: $!";
    my($string);
    my($n);
    my($n2);

    while(<IN>) {

	if(/($key )/) {
	    $n = $_;
		
	    $n =~ s/$key//;
	    my($h) = $n;

	    $n =~ s/(\w)+\s//;
	    $n =~ s/\s//g;
	    chomp($n);
	    $n =~ s/$host//;
	    $n =~ s/\s//g;
	    chomp($n);

	    $h =~ /(\w)+\s/;
	    $h = $&;
	    $h =~ s/\s//g;
            if ( $host eq $h) {
	      $n2 =$n;
	      $mode eq "-verbose" && print "$key $host: $n2\n";
	    }
	    
	}
	
    }
    
    close (IN);
    
    defined($n2) || ($n2=0);
# print("getOptionHost $key $host: $n2\n");        
    return ($n2);

}



sub getRAWrepository {

# Check input

    my($mode) =  $_[0];
    my($setupFile) = $_[1];

    my $key = "^CASTOR::RAW";

    my $n = getOption($mode,$setupFile,$key);

    return ($n);

}


sub getRAWrepository2 {

# Check input

    my($mode) =  $_[0];
    my($setupFile) = $_[1];

    my $key = "^CASTOR::HOSTRAW";

    my $n = getOptionHost($mode,$setupFile,$key);

    return ($n);

}

