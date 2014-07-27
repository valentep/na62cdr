#!/usr/bin/perl -w
# 
#
# Paolo Valente, July 2014
#
# Many problems with ../onl_cdr/complete-online.pl
#
# In order to safely test modifications created test-complete.pl 
#


require 5.004;
use strict;
use diagnostics;
use Time::Local;
use Sys::Hostname;   # Uli

use lib '../toolkit';

my($CCF_ROOT) = "/home/na62cdr/cdr";
chomp($CCF_ROOT);

require "$CCF_ROOT/toolkit/decode_fdb.pl";
#require "$CCF_ROOT/toolkit/getDirMask.pl";
require "./getDirMask_mod.pl";
require "$CCF_ROOT/toolkit/ErrorReport.pl";
require "$CCF_ROOT/toolkit/bkm_dir.pl";
require "$CCF_ROOT/toolkit/miscenv.pl";
require "./ls_stat_full.pl";

$ENV{STAGE_HOST}  = "castorpublic";
$ENV{STAGE_SVCCLASS}  = "na62";
$ENV{STAGE_POOL}  = "na62";
$ENV{RFIO_USE_CASTOR_V2}  = "YES";

my($hostcdr) = getHost();

# Check that this user is authorised to run CCF software 
my($user) = getUser();

my($bkm_dir);
my(@bkm_entry) = ();
my(%bkm_entry) = ();
%bkm_entry = bkm_dir("-quiet","$CCF_ROOT/setup/setup.dat");

foreach  (sort keys %bkm_entry) {
  if ( $hostcdr = $_) { $bkm_dir = $bkm_entry{$_}; }
}

die "$0: No bkm_dir on this host ($hostcdr). Check the setup.dat file..." unless defined($bkm_dir);

my($source,$target,$gstring,$candidate);

my(@cmdarg);

my($bkmrootdir) = $bkm_dir;

my($bkmstartdir)    = "$bkmrootdir/OnlineTransferStart";
my($bkmstopdir)     = "$bkmrootdir/OnlineTransferStop";
my($bkmcompletedir) = "$bkmrootdir/OnlineTransferComplete";
my($castordir)      = getRAWrepository2("-quiet","$CCF_ROOT/setup/setup.dat");
my($datadir)        = "/merger/cdr";

$hostcdr = getHost();

print "$0: Program is starting... ".`date`;
print `uname -a`;
print "host:                 $hostcdr\n";
print "bkmstartdir:          $bkmstartdir\n";
print "bkmstopdir:           $bkmstopdir\n";
print "bkmcompletedir:       $bkmcompletedir\n";
print "castordir:            $castordir\n";
print "datadir:              $datadir\n";


while() {

    print "TEST Looping... (no lock) date= ".`date`;

    # Create the files' bitmaps

    my %ready = ();
    my(@ready) =();

    my(%problem) = getDirMask_mod("$bkmstartdir","$bkmstopdir","$bkmcompletedir","$datadir");

    foreach (keys %problem) {
	
	if($problem{$_}[0] eq "1001") { # started but not stopped
	    my $problem = "$bkmstartdir/$_";
	    my $cur_time = time();
	    print "Started but not stopped: $problem\n";
	    my $file_time = (stat($problem))[9]; # modtime
	    if(($cur_time-$file_time)>3600) { # 1 hour 
		print("TEST remove $problem\n");
	    }
	}
    }

    %ready = getDirMask_mod("$bkmstartdir","$bkmstopdir","$bkmcompletedir","$datadir");

    foreach (keys %ready) {
	if($ready{$_}[0] eq "1101") {
	    my $thefile = "$bkmstopdir/$_";
	    print ("TEST pushing into list $thefile\n");
	    push @ready,"$thefile";
	}
    }

    for (@ready) {
	my $castorfile = $_;
	my $disk_file  = $_;
	my $stop_file  = $_;
	my $start_file = $_;
	$start_file =~ s/$bkmstopdir/$bkmstartdir/;
	$disk_file  =~ s/$bkmstopdir/$datadir/;
	$castorfile =~ s/$bkmstopdir/$castordir/;

	my @disk_stat = ls_stat_full($disk_file);
	my @castor_stat = nsls_stat_mod($castorfile);
	my $cur_time = time();
	my $file_age = (stat("$stop_file"))[9]; # mtime

	print "\n";
	if (@disk_stat){
	    if(@castor_stat){
	    }else{
		print "Error! $disk_file exists, but $castorfile NOT found!\n";
	    }
	}else{
	    print "Error! $disk_file NOT found!";
	    if(@castor_stat){
		print " \n";
	    }else{
		print "Also $castorfile NOT found!\n";
	    }
	}

	print "TEST >>>>>> $source $target \n";

	if (defined($castor_stat[0]) && ($castor_stat[0] =~ /^\/castor\//)) {
#	    print "TEST >>> $castor_stat[0] is a CASTOR path\n";
	    if (($castor_stat[0] ne "") && ($castor_stat[3] =~ /^m/) && ($castor_stat[1] != 0)
	        && ($disk_stat[1] == $castor_stat[1]) && ($cur_time-$castor_stat[2]) > 1800) # test migration, size, time
	    {
#		print "TEST >>> $castor_stat[0] migrated and size equals disk version: $disk_stat[0]\n";
		my $source = $_;
		my $target = $_;
		$target =~ s/$bkmstopdir/$bkmcompletedir/;
		print("$disk_stat[0] has been migrated on tape successfully, mark it as completed.\n");
		@cmdarg = ("cp","$source","$target");
		print("@cmdarg\n");
		print("TEST -- IF can't create bookmark file $target, remove it\n");
	    }
	    elsif ($castor_stat[1] == 0 || $disk_stat[1] != $castor_stat[1]) # castor file size 0 or wrong size
	    {
		print "TEST >>> $castor_stat[0] has wrong or zero size: $castor_stat[1] (disk: $disk_stat[1]) \n";
		if (($cur_time-$file_age) > 40000) # more than 12 hours
		{
		  print("Error: Size of $disk_stat[0] = $disk_stat[1]\n       Size of $castor_stat[0] = $castor_stat[1]\n");
		  # Error recovery:
		  print("Remove bkm files: $stop_file and $start_file\n");
		  print("Bad castor file size for $disk_stat[0] ($disk_stat[1] against $castor_stat[1])\n");
		  print("TEST rm $stop_file\n");
		  print("TEST rm $start_file\n");
		  print("Remove Castor file: $castor_stat[0]\n");
		  print("TEST rfrm $castor_stat[0]\n");
		}
	    }
	    elsif(($castor_stat[3] =~ /^\-/) && ($castor_stat[0] ne 0))   
#Not yet the "m" in the castor nsls -l output (not on tape but only on castor disks
	    {
		if(($cur_time-$file_age) > 40000) # more than 12 hours
		{
		    print("WARNING: File $castor_stat[0] still not migrated to tape.\n");
		}
	    }
	}
    }
    
    print("Sleep 2 minutes before next cicle...\n");
    sleep 120;
}


