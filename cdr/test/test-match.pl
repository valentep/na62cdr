#!/usr/bin/perl -w
#
# Small test program                                                                                                                                                          
#
# P.V. 11 July 2014
#                  

require 5.004;
use strict;
use diagnostics;

my $entry="cdr-2014-00123456-0001.dat";

if (
     $entry=~/cdr([\d\-\_]*)(\.dat)/   # normal cdr filename format
     ||
     $entry=~/straw([\d\-\_]*)(\.dat)/   # straw cdr filename format
     ||
     $entry=~/lkr([\d\-\_]*)(\.dat)/   # Liquid Krypton cdr filename format 
    ){
    my($key) = $&;
    print "$entry matches $key\n";
}else{
    print "$entry not matched!\n";
}
