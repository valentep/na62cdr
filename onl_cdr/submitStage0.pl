#!/usr/bin/perl -w

# Author: Felice Pantaleo (felice.pantaleo@cern.ch), Massimo Lamanna
# $Id: submitStage0.pl,v 1.11 2012/10/26 17:37:45 neyret Exp $
# P.V. 2014 version
#

require 5.004;
use strict;
use diagnostics;
#
use Time::Local;
use Sys::Hostname;   # Uli
#

my($CCF_ROOT) = `grep CCF_ROOT $ENV{HOME}/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'`;
defined $CCF_ROOT || die "Home directory CCF_ROOT not found in configuration file $ENV{HOME}/.ccfrc";
chomp($CCF_ROOT);
print "===============================================================\n";
print "===============================================================\n";
print "CCF_ROOT      ",$CCF_ROOT,"\n";

require "$CCF_ROOT/toolkit/decode_fdb_mod.pl";
require "$CCF_ROOT/toolkit/bkm_dir.pl";
require "$CCF_ROOT/toolkit/getDirMask_mod.pl";
require "$CCF_ROOT/toolkit/ls_stat_full.pl";
require "$CCF_ROOT/toolkit/miscenv_mod.pl";

my($setupfile) = "$CCF_ROOT/setup/setup.dat";
my($usersfile) = "$CCF_ROOT/setup/users.dat";
#######################################################

# Get host name
my($host) = getHost();
# Check that this user is authorised to run CCF software 
my($user) = getUser_mod($usersfile);
print "Host:         $host\n";
print "User:         $user\n";
#
print "Parsing setup file: $setupfile\n";
my($datayear) = getDataYear("-quiet",$setupfile);
my($datadir) = getDataDir("-quiet",$setupfile);
print "Processing year:    $datayear\n";
print "datadir:            $datadir\n";
#
my($castordir) = getRAWrepository2("-quiet",$setupfile);
my $rawdatamigr = getDataMigrCommand("-quiet",$setupfile);

$ENV{RAWDATAMIGR_TIMEOUT} = getDataMigrTimeout("-quiet",$setupfile);

my($castorusev2)    = getCASTORusev2("-quiet",$setupfile);
$ENV{RFIO_USE_CASTOR_V2}  = $castorusev2;

if ($castorusev2 eq "YES") {
# define Castor-2 stager, and service class (= disk pool)
    $ENV{STAGE_HOST}  = getCASTORstagehost("-quiet",$setupfile);
    $ENV{STAGE_SVCCLASS}  = getCASTORsvcclass("-quiet",$setupfile);
    $ENV{STAGE_POOL}  = getCASTORstagepool("-quiet",$setupfile);
}else{
# force rfcp and other rf* commands to follow Castor-2 protocols
    die "You must choose Castor-2 protocol in setup file: $setupfile";
}

my(@bkm_entry) = ();
my(%bkm_entry) = ();
%bkm_entry = bkm_dir("-quiet",$setupfile);

my($logsdir) = getLogsDir("-quiet",$setupfile);
my $statusOKFileName = "$logsdir/onl_cdr/submitStage0.status.ok";
my $statusErrorFileName = "$logsdir/onl_cdr/submitStage0.status.error";

my($bkm_dir);

foreach  (sort keys %bkm_entry) {
  if ( $host = $_) { $bkm_dir = $bkm_entry{$_}; }
}

die "$0: No bkm_dir on this host ($host). Check the setup.dat file..." unless defined($bkm_dir);

my($bkmrootdir,$bkmstopdir,$bkmsubmitdir);

my(@cmdarg);

# Checks/prepare bkm rootdir
$bkmrootdir = $bkm_dir;
if(!(-d $bkmrootdir)) {die "$0: $bkmrootdir does not exist\n";}

# Checks/prepare bkm stopdir
$bkmstopdir = $bkmrootdir."/OnlineDataComplete";
if(!(-d $bkmstopdir)) {die "$0: $bkmstopdir does not exist\n";}

# Checks/prepare bkm submitdir
$bkmsubmitdir = $bkmrootdir."/OnlineTransferStart";
if(!(-d $bkmsubmitdir)) {die "$0: $bkmsubmitdir does not exist\n";}

# Checks/prepare bkm submitdir
my($bkmenddir);
$bkmenddir = $bkmrootdir."/OnlineTransferStop";
if(!(-d $bkmenddir)) {die "$0: $bkmenddir does not exist\n";}

# Sleep time after a successful cleanup and a empty search
my($lastsearch) = 0;
my($wait0) = getWaitLong("-quiet",$setupfile); 
my($wait1) = getWaitShort("-quiet",$setupfile); 

print "$0: starting... ".`date`;
print `uname -a`;
print "bkmrootdir:   $bkmrootdir\n";
print "bkmstopdir:   $bkmstopdir\n";
print "bkmsubmitdir: $bkmsubmitdir\n";
print "bkmenddir:    $bkmenddir\n";
print "castordir:    $castordir\n";

my $lock_file = "$CCF_ROOT/lockfiles/submitStage0.$host.lock";

my $num_candidate = 0; # counter of candidates for selecting fraction of them to be staged to compass_anal as well

if(-e $lock_file) {
    system "touch $statusErrorFileName";
    die "Lock file found...";
}
system("killall $rawdatamigr");  # kill all remaining rawdatamigr (sometimes many rawdatamigr are present, which is bad)

my($source,$target,$gstring,$candidate,$disk_file,$castorfile);

while() {
    if(-e $lock_file) {
	system "touch $statusErrorFileName";
	die "Lock file found...";
    }

    my %ready = ();
    my(@ready) =();

    %ready = getDirMask_mod("$bkmstopdir","$bkmsubmitdir","$bkmenddir");
    foreach (keys %ready) {
	if($ready{$_}[0] eq "100") {
	    push @ready,"$bkmstopdir/$_";
	}
    }
    my $nready=0;
    for (@ready) {
	$lastsearch = 1;
	$nready++;
#	print "*** $_ \n";
    }

# Sleep to avoid to mess up bkm files while they are still
# being transfered (ML 21-5-1999)
    my($waittime);
    if($lastsearch == 0 ) {
	$waittime = $wait0;
    }
    else {
	$waittime = $wait1;
    }
    print "Found $nready bookmarks ready\n";
    system "touch $statusOKFileName";
    print "$0: Before next cycle... sleep $waittime s\n";
    sleep($waittime);

    print "Looping...  date= ".`date`;
    for (@ready) {
      if(-e "$lock_file") {
	system "touch $statusErrorFileName";
	die "Lock file found...";
      }
      $lastsearch = 0;
      $source = $_;
      $target = $_;
      $castorfile = $_;
      $disk_file  = $_;
      $target =~ s/$bkmstopdir/$bkmsubmitdir/;
      $disk_file  =~ s/$bkmstopdir/$datadir/;
      $castorfile =~ s/$bkmstopdir/$castordir/;
###      $castorfile =~ s/\.dat/\.raw/;
      my $newdate = `date +\"%d %b %Y %H:%M:%S\"`;
      my $newseconds = `date +\"%s\"`;
      print "===============================================================\n\n";
      print "*** Reading new file ***\n\n";
      print "$newdate\n";
      print "\nsource:       $source\n";
      print "target:       $target\n";
      print "targetdir:    $bkmsubmitdir\n";
      print "disk file:    $disk_file\n";
      print "castor file:  $castorfile\n";
      
      if(!(-e $source)) {
	  system "touch $statusErrorFileName";
	  die "$0: Propagate error: $source";
      }
      open (IN,$source) || die "$0: cannot open $source for reading: $!";
      $gstring =  <IN>;
      my $test = $gstring;    # bug fix: the bkm-file is not empty, but filled by 0 
      $test =~ s/\0//g;       # if EVB was off due to power cut.
      my $l = length($test);  # So, has to be tested.
      if(!defined($gstring) || $l == 0) {
	  system "touch $statusErrorFileName";
	  print "Invalid $source file: probably empty\n";
	  print "Check if it OK in source dir, delete the empty one\n";
	  print "by hand (and restart)\n";
	  next;
      } 
      chomp($gstring);
      die "Cannot understand bkm $source" unless $gstring =~ /(\S)*/;
      $candidate = $&;
######
      my $datasize = 0;
      my $anotherstring =  <IN>; 
      if($anotherstring =~ /size\:\s+([\d]+)/) {
	  $datasize=$1;
      }
      $anotherstring =  <IN>;
#     datetime: 13-04-14_05:15:43      
      my $thisyear = 0;
      if($anotherstring =~ /datetime\:+\s+([\d]+)\-([\d]+)\-([\d]+)\_([\d]+):([\d]+)\:([\d]+)/) {
	  $thisyear=$3;
      }
      $thisyear=$thisyear+2000;
######
      close (IN);
      if($thisyear != $datayear){
	  print "File $candidate belonging to year $thisyear (not $datayear); skip...\n";
	  next;
      }
# Check if Castor file already exists, remove it if it is old
      my @castor_stat = nsls_stat_mod($castorfile);
      my $cur_time = time();
      # remove Castor files not migrated, more than 1 day old, size 0
      if ($castor_stat[0]) {
	if (($castor_stat[3] =~ /^-/) && ($cur_time-$castor_stat[2]) > 36000 && ($castor_stat[1] == 0))
	{
	  print("\nError: Castor file already exist, name $castor_stat[0] size $castor_stat[1]\n");
	  print("Remove Castor file $castor_stat[0]\n\n\n");
          system("rfrm $castor_stat[0]");
	  system "touch $statusErrorFileName";
	  sleep 10;
	}
      }
# Dump transfer start
      my($fname) = $candidate;
      die "Cannot extract filename for $candidate" 
#	  unless $fname =~ /\/(cdr\d+-\d+\.dat)/;
      unless $fname =~ /\/(\w+\d+-\d+\_{0,1}\d+\.dat)/;
      $fname = $1;
      if(!(defined $fname)) {
	  system "touch $statusErrorFileName";
	  print "$0: transfer candidate filename failure; skip...\n";
	  system "touch $statusErrorFileName";
	  next;
      }
      print "transfer candidate $candidate\n";

# BKM Start
      @cmdarg = ("cp","$source","$bkmsubmitdir");
      print ("@cmdarg\n");
      system(@cmdarg) == 0 || die "$0: @cmdarg: $!";
      system("ls -l $bkmsubmitdir/$fname");

# Data transfer
      my $execresult = 1;
      if($execresult != 0) {
	  @cmdarg = ("time","$rawdatamigr","$candidate","$castordir");
	  print ("command to launch: @cmdarg\n");
#      system("printenv");
	  $execresult = system(@cmdarg);
      }
      print "$0: rawdatamigr return code: $execresult\n";
      unless($execresult==0){
#	  system("rm $target");
	  next;
      }
      $source = $_;
      $target = $_;
      $target =~ s/$bkmstopdir/$bkmenddir/;
      print "\n";
      print "source:       $source\n";
      print "target:       $target\n";
      print "targetdir:    $bkmenddir\n";
      my $nbseconds = `date +\"%s\"` - $newseconds;
      print "treatment time: $nbseconds s\n";
      system("ls -l $candidate");
      if(!(-e $source)) {
	  system "touch $statusErrorFileName";
	  die "$0: Propagate error: $source";
      }
      $gstring = "$castordir/$fname $gstring";
#    print "New bkm contains: $gstring\n";
    
# BKM Stop
      open (OUT,">$target") || die "$0: cannot open $target for writing: $!";
      print OUT $gstring;
      close (OUT);
      system "touch $statusOKFileName";
      print "File $candidate sent to tape...\n";
      print "DEBUG remember to remove sleep\n";
      sleep 60;
  }
}



