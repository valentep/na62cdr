#ls -l
#-rw-r--r--. 1 na62cdr vl 46710204 19 dic  2013 /merger/cdr/cdr00002129-0005.dat
#-rw-r--r--. 1 na62cdr vl 54201352  4 apr 11:33 /merger/cdr/cdr00002191-0021.dat
#
#
#ls -l --time-style="+%Y-%m-%d %H:%M:%S"
#-rw-r--r--. 1 na62cdr vl 46710204 2013-12-19 12:05:06 /merger/cdr/cdr00002129-0005.dat
#-rw-r--r--. 1 na62cdr vl 54201352 2014-04-04 11:33:34 /merger/cdr/cdr00002191-0021.dat

require 5.004;

use strict;
use diagnostics;

use Time::Local;

sub ls_stat_full {
# 
# P.V. changed ls -l command options in order to be independent from the laguage
# Indeed merger machine used in 2012-2014 has LANG=it_IT.UTF-8, 
#      so months name are Gen, ..., Giu, Lug, ...
#                 and not Jan, ..., Jun, Jul, ...
#
# With --time-style option also one has a simpler extraction of file time
#
    my @arg = @_;
    my @ret_stat = ();
    my $ls_cmd = "ls -l --time-style=\"+\%Y-\%m-\%d \%H:\%M:\%S\"";
    my $nsls_ret = `$ls_cmd $arg[0]`;
#    print "TEST LS_STAT ### $nsls_ret\n";
    if($nsls_ret =~ /([\S]+)\s+([\S]+)\s+([\S]+)\s+([\S]+)\s+([\d]+)\s+([\d]+)\-([\d]+)\-([\d]+)\s+([\d]+)\:([\d]+)\:([\d]+)\s+([\S]+)/) {
	my $fperm = $1;
	my $fnumb = $2;
	my $owner = $3;
	my $group = $4;
	my $fsize = $5;
	my $fyear = $6;
	my $fmon  = $7-1;
	my $fmday = $8;
	my $fhour = $9;
	my $fmin  = $10;
	my $fsec  = $11;
	my $ftime = timelocal($fsec,$fmin,$fhour,$fmday,$fmon,$fyear);
	my $fname = $12;
	@ret_stat = ($fname,$fsize,$ftime,$fperm);	
    }
    return @ret_stat;
}

#/usr/bin/nsls -l /castor/cern.ch/na62/data/2013/raw/tmp/cdr00002287-3823.dat
#mrw-r--r--   1 na62cdr  vl                 38403876 Jul 14 16:15 /castor/cern.ch/na62/data/2013/raw/tmp/cdr00002287-3823.dat
#/usr/bin/nsls -l /castor/cern.ch/na62/data/2012/raw/tmp/cdr00099948-0000_2.dat
#mrw-r--r--   1 na62cdr  vl                   932656 Jan 18  2013 /castor/cern.ch/na62/data/2012/raw/tmp/cdr00099948-0000_2.dat

sub nsls_stat_mod {
# 
# P.V. 
# Not possible to have --time-style option in nsls -l command 
# but it's reasonable to assume this command to always answer with english month names...
#
    my @arg = @_;
    my @ret_stat = ();
    my $nsls_ret = `/usr/bin/nsls -l $arg[0]`;

my %months = qw(
		Jan     0
		Feb     1
		Mar     2
		Apr     3
		May     4
		Jun     5
		Jul     6
		Aug     7
		Sep     8
		Oct     9
		Nov    10
		Dec    11
		);
    my ($nsec,$nmin,$nhour,$nmday,$nmon,$nyear,$nwday,$nyday,$nisdst) = localtime();

    if($nsls_ret =~ /([\S]+)\s+([\S]+)\s+([\S]+)\s+([\S]+)\s+([\d]+)\s+([\S]+)\s+([\d]+)\s+([\d]+)\:([\d]+)\s+([\S]+)/) {
	my $fperm = $1;
	my $fnumb = $2;
	my $owner = $3;
	my $group = $4;
	my $fsize = $5;
	my $fmon  = $months{$6};
	my $fmday = $7;
	my $fyear = $nyear+1900;
	my $fhour = $8;
	my $fmin  = $9;
# 
# P.V. fixed timelocal translation
#
	my $ftime = timelocal(0,$fmin,$fhour,$fmday,$fmon,$fyear);
	my $fname = $10;
	@ret_stat = ($fname,$fsize,$ftime,$fperm);	
#	print "TEST NSLS $fmday $fmon $fyear $fname\n";
    }else{ 
# 
# P.V. one should take into account files older than 1 year!
#
	if($nsls_ret =~ /([\S]+)\s+([\S]+)\s+([\S]+)\s+([\S]+)\s+([\d]+)\s+([\S]+)\s+([\d]+)\s+([\d]+)\s+([\S]+)/) {
	    my $fperm = $1;
	    my $fnumb = $2;
	    my $owner = $3;
	    my $group = $4;
	    my $fsize = $5;
	    my $fmon  = $months{$6};
	    my $fmday = $7;
	    my $fyear = $8;
	    my $ftime = timelocal(0,0,0,$fmday,$fmon,$fyear);
	    my $fname = $9;
	    @ret_stat = ($fname,$fsize,$ftime,$fperm);	
#	    print "TEST NSLS_ $fmday $fmon $fyear $fname\n";
	}
    }
    return @ret_stat;
}






