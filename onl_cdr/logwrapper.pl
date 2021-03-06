#! /usr/bin/perl -w
# Author: Ulrich Fuchs (Ulrich.Fuchs@cern.ch) 2001
# edited by V.Frolov (2003)
# $Id: logwrapper.pl,v 1.1 2003/07/29 16:55:51 objsrvvy Exp $

require 5.004;
use strict;
use diagnostics;

# my($CCF_ROOT)="/usr/local/compass/ccf";
my($CCF_ROOT)="/home/na62cdr/cdr";
if(-e "$ENV{HOME}/.ccfrc") {
    $CCF_ROOT = `cat "$ENV{HOME}/.ccfrc" 2>&1`;
    chomp($CCF_ROOT);
    $CCF_ROOT =~ s/CCF_ROOT//;
    $CCF_ROOT =~ s/ //g;
}
if(!-d $CCF_ROOT) {
    $CCF_ROOT = "/home/na62cdr/cdr";
}

use Sys::Hostname;
my $host=hostname();
$host=~ s/\..*//;

my $file="/tmp/ccf/$host.viewlog.dat";

open FILE, ">$file";
print FILE "VIEWLOG generated by logwrapper.pl automatically \n\n\n";
close FILE;

system("$CCF_ROOT/onl_cdr/viewlog.pl >> $file");
