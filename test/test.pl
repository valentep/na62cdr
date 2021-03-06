#!/usr/bin/perl -w
#
# Small test program                                                                                                                                                          
#
# P.V. 11 July 2014
#                  

require 5.004;
use strict;
use diagnostics;

require "./getDirMask_mod.pl";
require "./ls_stat_full.pl";
#require "./getDirMask_orig.pl";

#my($bkmdir)="/home/na62cdr/cdr/test";
my($bkmdir)="/merger/bkm";

ls_stat_full($bkmdir);

#my(@dirs)=("DataComplete","TransferStart","TransferStop","TransferComplete","DataLKr","DataStop","DataClear");       
my(@dirs)=("DataStop","TransferStart","TransferStop","TransferComplete","DataLKr","DataComplete","DataClear");       

my $i=0;
print "| ";
foreach my $dire (@dirs) {
    print $dire," | ";
    $dirs[$i]=$bkmdir."/Online".$dire;
    $i++;
}       
print "\n";

my(%run) = getDirMask_mod(@dirs);
#my(%run) = getDirMask_orig(@dirs);

foreach (keys %run) {                                       
    print "$_ mask: $run{$_}[0]\n";
}       
