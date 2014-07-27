#!/usr/bin/perl -w
# Author: Massimo Lamanna (Massimo.Lamanna@cern.ch) June 1999
# Modifications Massimo Lamanna June 2000
# $Id: viewlog.pl,v 1.1 2003/07/29 16:56:11 objsrvvy Exp $ 

require 5.004;
use strict;
use diagnostics;

my($CCF_ROOT) = "/home/na62cdr/cdr";
defined $CCF_ROOT || die "Define CCF_ROOT enviroment variable";
chomp($CCF_ROOT);

# require "$CCF_ROOT/toolkit/objyenv.pl";
require "$CCF_ROOT/toolkit/miscenv.pl";

my($host) = getHost();

my $cluster = belongCluster($host,"$CCF_ROOT/setup/setup.dat");
my %controlhash = ();
my $logdir;

for ($cluster) {

#--------------------- program - number of expected ----
#   %controlhash = qw( 
#                    );
#

    if (/NONE/) { 
	die "Unrecognised cluster $cluster ...";
    }
    
    if (/COF/) {
	%controlhash = qw (
			   onl_cdr/interface_online.pl  1
			   onl_cdr/submitStage0.pl   1      
			   onl_cdr/cleanup_online.pl    1      
			   onl_cdr/complete_online.pl     1
			   );
	$logdir = "/tmp/ccf";
    }
    else {
	die "Unimplemented keyword $cluster ...";
    }
    
}

my $dir;
for $dir (keys(%controlhash)) {
    $dir =~ s/\s//g;
    $dir =~ s/\/.*//g;
    if(!-e "$logdir/$dir") { #permissions not checked...yet
	print "$logdir/$dir does not exists...\n";
    }
}

my($script) = $0;
$script =~ s/.*\///;

print "$script: ".`date`;
print "logfiles on host $host ($cluster)\n";;

my $log = "$logdir/onl_cdr/master.log";
$log =~ s/\.pl\.log/\.log/;

print "\n\n";
print "\n-----------------------------------------------------------\n";
print "logfile $log\n";
print `ls -l $log`;
print "-----------------------------------------------------------\n";
system ("tail -30 $log");

for (keys(%controlhash)) {

    $log = "$logdir/$_.log";
    $log =~ s/\.pl\.log/\.log/;

    if(-e $log){
	print "\n\n";
	print "\n-----------------------------------------------------------\n";
	print "logfile $log\n";
	print `ls -l $log`;
	print "-----------------------------------------------------------\n";
	system ("tail -30 $log");
    }else{
	print "\n\n";
	print "\n-----------------------------------------------------------\n";
	print "logfile $log\n";
	print "-----------------------------------------------------------\n";
	print "Logfile $log does not exist \n\n";
    }
}

$log = "/tmp/ccf/cdr/rawdatamigr.dat";
print "\n\n";
print "\n-----------------------------------------------------------\n";
print "logfile $log\n";
print `ls -l $log`;
print "-----------------------------------------------------------\n";
system ("tail -30 $log");

print "\n\n\n\n\n\n\n\n\n\n";
exit;





sub belongCluster {

# Check input

    my($host) =  $_[0];
    my($setupFile) = $_[1];
#   print "$mode\n";
#   print "$setupFile\n";

    defined $host      || die "$0: Undefined host";
    defined $setupFile || die "$0: Undefined setup file";

    (-r $setupFile) || die "$0: Cannot access $setupFile";

# Open setup file
    
    open (IN,$setupFile) || die "$0: cannot open $setupFile for reading: $!";
    my($string);

    my($cluster) = "NONE";

    my $hasGDC = 0;
    my $hasBKM = 0;
    my $hasCDR = 0;
    my $hasRAW = 0;
    my $hasAMS = 0;

    while(<IN>) {

	if(/$host/) {
	    /^GDC / && $hasGDC++;
	    /^BKM / && $hasBKM++;
	    /^CDR / && $hasCDR++;
	    /^RAW / && $hasRAW++;
	    /^AMS / && $hasAMS++;
	}

    }
    
    close (IN);

    my $CCF = $hasCDR + $hasRAW + $hasAMS;

    if( $hasGDC > 0 && $hasBKM == 1 && $CCF==0 ) {
	return ("COF");
    }
    elsif( $hasGDC == 0 && $hasBKM == 1 && $CCF>0 ) {
	return ("CCF");
    }

    print "nGDC = $hasGDC\n";
    print "nBKM = $hasBKM\n";
    print "nCDR = $hasCDR\n";
    print "nRAW = $hasRAW\n";
    print "nAMS = $hasAMS\n";
    return ("NONE");
    
    return ($cluster);

}



