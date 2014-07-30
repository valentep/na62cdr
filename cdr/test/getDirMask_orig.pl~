#!/usr/bin/perl -w
# Author: Ulrich Fuchs (Ulrich.Fuchs@cern.ch) 2000
# Modified: Massimo Lamanna (Massimo.Lamanna@cern.ch) June 2000
#
# The input parameter is a @dir containing the full path
# of the directories. The output is a %run with key the
# filename (without the directory) and value a string
# containing the mask (0 missing, 1 present)
#
# In the comments there is a small example program
#
# Main change is that the hash has a single value, which 
# can be seen as a bit map of found/missing files. 
# This makes easier printout and handling of trigger conditions (?)bkm
#
# $Id: getDirMask.pl,v 1.8 2003/07/29 18:11:06 objsrvvy Exp $

require 5.004;

use strict;
use diagnostics;

# Small test program
#
# my($bkmdir)="/shift/ccf018d/data01/objsrvvy/bkm";
# my(%run) = 
#     getDirMask("$bkmdir/OnlineDataStart",
#	         "$bkmdir/OnlineTransferStop",
#	         "$bkmdir/DumpTransfersStart",
#	         "$bkmdir/DumpTransferStop");
# foreach (keys %run) {
#     print "$_ $run{$_}[0]\n";
# }

sub getDirMask(){

    use integer; # Use integer arithmetics

    my(@dir) = @_; # Input: list of full specified directories

    my(%run)=();   # Output: hash of file names (stripped) and mask

    my($mask) = 2**$#dir;

    die "Too many directories (max 32)" unless $#dir<32;
 
    for (my($i)=0;$i<=$#dir;$i++){

	if (opendir(DIR,$dir[$i])) {
	    my($entry);
	    while ( defined( $entry = readdir(DIR)) ){
#match to be improved: 
		if (
		    $entry=~/cdr([\d\-\_]*)(\.dat)/   # normal cdr filename format
     #   $entry=~/\/\w+(\d+-\d+_{0,1}\d+)(\.dat)$/   # 5-5.dat format		    
        ||
		    $entry=~/straw([\d\-\_]*)(\.dat)/   # straw cdr filename format
		    ||
		    $entry=~/lkr([\d\-\_]*)(\.dat)/   # Liquid Krypton cdr filename format
		    ){
		    my($key) = $&;
		    if (! (defined $run{$key}[0])){  # found new run !
			$run{$key}[0] = $mask;       # load the first zero...
		    }
		    else {
			$run{$key}[0] += $mask;      # switch on a new bit
		    }
	    
		    
		}
	    }
	    closedir(DIR);
	}
	else {
	    print "$0: cannot open $dir[$i]: $!\n";
	}
	$mask /= 2;  # Move the bit one step down (left to right)
    }
    
# Overwrite with strings like "111" instead of integer 7...

    foreach (keys %run) {
	my($bin) = dec2bin($run{$_}[0]);
	my($leading) = $#dir + 1 - length($bin);
	for(my $i=0;$i<$leading;$i++) {$bin = "0".$bin;}
	$run{$_}[0] = $bin;
    }


    return %run;

}

# Put an integer in a string to appear a binary
# Perl Cookbook p.48
sub dec2bin {
    my $str = unpack("B32",pack("N",shift));
    $str =~ s/^0+(?=\d)//; #otherwise leading zeros
    return $str;
}

# Inverse of dec2bin
# Perl Cookbook p.48
sub bin2dec {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}


