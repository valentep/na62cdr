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
# This makes easier printout and handling of trigger conditions (?)
#
# $Id: getDirMask1.pl,v 1.1 2003/09/23 09:27:35 objsrvvy Exp $

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


    die "Too many directories (max 9)" unless $#dir<10;
 
    for (my($i)=0;$i<=$#dir;$i++){

      my($mask) = 2**($#dir-$i);
	if (opendir(DIR,$dir[$i])) {
	    my($entry);
	    while ( defined( $entry = readdir(DIR)) ){
	      my $ttt = $entry;
#	      if( $ttt =~ /^cdr\d{2,2}\-\d{5,5}_\d{3,3}\.raw/ )
	      if( $ttt =~ /^cdrpcco[er]b\d{2,2}-\d{3,6}.\d{3,3}.raw/ )
		  {
		    $_ = $entry;
#		    /(\w{3,3})(\d{2,2})\-(\d{5,6})\_(\d{3,3})\.raw/ ;
#		    my $newname = "$1$2$4-$3.dat";
		    /cdrpcco[er]b(\d{2,2})\-(\d{3,6})\.(\d{3,3})\.raw/ ;
		    my $newname = "cdr$1$3-$2.dat";
		    $entry = $newname;
		  }
	      if( $ttt =~ /^cdrpcco[er]b\d{2,2}-\d{3,6}.raw/ )
		  {
		    $_ = $entry;
#		    /(\w{3,3})(\d{2,2})\-(\d{5,6})\_(\d{3,3})\.raw/ ;
#		    my $newname = "$1$2$4-$3.dat";
		    /cdrpcco[er]b(\d{2,2})\-(\d{3,6})\.raw/ ;
		    my $newname = "cdr$1-$2.dat";
		    $entry = $newname;
		  }
#match to be improved: 
	      if (
		  $entry=~/^cdr([\d-]*)(\.dat)$/   # 5-5.dat format
#		  ||
#		  $entry=~/^cdr\d{5,6}$/           # (5-6)-digit run number
		  ||
		  $entry=~/^cdr([\d\-_]*)(\.raw)$/   # lars.raw format
		  ){
		my($key) = $&;
		if (! (defined $run{$key}[0])){  # found new run !
		  if( (-z "$dir[$i]/$ttt") ) # file is corrupted
		  {
		    $run{$key}[1] = $mask;
		  }
		  else
		  {
		    $run{$key}[1] = 0;
		  }
		  $run{$key}[0] = $mask;       # load the first zero...
		}
		else {
		  if( (-z "$dir[$i]/$ttt") ) # file is corrupted
		  {
		    $run{$key}[1] |= $mask;
		  }
		  $run{$key}[0] |= $mask;      # switch on a new bit
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
	$bin = dec2bin($run{$_}[1]);
	$leading = $#dir + 1 - length($bin);
	for(my $i=0;$i<$leading;$i++) {$bin = "0".$bin;}
	$run{$_}[1] = $bin;
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
