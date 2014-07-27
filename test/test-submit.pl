#!/usr/bin/perl -w

# test script for CASTOR 2, DN 26/3/2007
# Steer an optional dump into CASTOR
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

my($CCF_ROOT) = `grep CCF_ROOT $ENV{HOME}/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'` || "/home/na62cdr/cdr";
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

### final configuration setup.dat.2014 -> setup.dat ###
my($setupfile) = "$CCF_ROOT/setup/setup.dat.2014";
my($usersfile) = "$CCF_ROOT/setup/users.dat";
#######################################################


# Get host name
my($host) = getHost();
# Check that this user is authorised to run CCF software 
my($user) = getUser_mod($usersfile);
print "Host:         $host\n";
print "User:         $user\n";

my($datayear) = getDataYear("-quiet",$setupfile);

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

my($castordir) = getRAWrepository2("-quiet",$setupfile);
my($datadir) = getDataDir("-quiet",$setupfile);
my $rawdatamigr = getDataMigrCommand("-quiet",$setupfile);

$ENV{RAWDATAMIGR_TIMEOUT} = getDataMigrTimeout("-quiet",$setupfile);

my(@bkm_entry) = ();
my(%bkm_entry) = ();
%bkm_entry = bkm_dir("-quiet",$setupfile);

my($logsdir) = getLogsDir("-quiet",$setupfile);
my $statusOKFileName = "$logsdir/submitStage0.status.ok";
my $statusErrorFileName = "$logsdir/submitStage0.status.error";

my($bkm_dir);

foreach  (sort keys %bkm_entry) {
  if ( $host = $_) { $bkm_dir = $bkm_entry{$_}; }
}

die "$0: No bkm_dir on this host ($host). Check the setup.dat file..." unless defined($bkm_dir);

my($bkmrootdir,$bkmstopdir,$bkmsubmitdir);

my(@cmdarg);

# Checks/prepare bkm rootdir
$bkmrootdir = $bkm_dir;
if(!(-d $bkmrootdir)) {die "$0: bkmrootdir does not exist\n";}

# Checks/prepare bkm stopdir
$bkmstopdir = $bkmrootdir."/OnlineDataComplete";
if(!(-d $bkmstopdir)) {die "$0: bkmstopdir does not exist\n";}

# Checks/prepare bkm submitdir
$bkmsubmitdir = $bkmrootdir."/OnlineTransferStart";
if(!(-d $bkmsubmitdir)) {die "$0: bkmsubmitdir does not exist\n";}

# Checks/prepare bkm submitdir
my($bkmenddir);
$bkmenddir = $bkmrootdir."/OnlineTransferStop";
if(!(-d $bkmenddir)) {die "$0: bkmsubmitdir does not exist\n";}

# Sleep time after a successful cleanup and a empty search
my($lastsearch) = 0;
my($wait0) = getWaitLong("-quiet",$setupfile); 
my($wait1) = getWaitShort("-quiet",$setupfile); 

print "bkmrootdir:   $bkmrootdir\n";
print "bkmstopdir:   $bkmstopdir\n";
print "bkmsubmitdir: $bkmsubmitdir\n";
print "bkmenddir:    $bkmenddir\n";
print "castordir:    $castordir\n";

my $lock_file = "$CCF_ROOT/lockfiles/submitStage0.$host.lock";

my $num_candidate = 0; # counter of candidates for selecting fraction of them to be staged to compass_anal as well

my($source,$target,$gstring,$candidate,$disk_file,$castorfile);

while() {
    my %ready = ();
    my(@ready) =();

    %ready = getDirMask_mod("$bkmstopdir","$bkmsubmitdir","$bkmenddir");
    foreach (keys %ready) {
	if($ready{$_}[0] eq "100") {
	    push @ready,"$bkmstopdir/$_";
	}
    }

    for (@ready) {
	$lastsearch = 1;
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
    print "$0: Before next cycle... sleep $waittime s\n";
    sleep($waittime);
    print "Looping...  date= ".`date`;
    for (@ready) {
      $lastsearch = 0;
      $source = $_;
      $target = $_;
      $castorfile = $_;
      $disk_file  = $_;
      $target =~ s/$bkmstopdir/$bkmsubmitdir/;
      $disk_file  =~ s/$bkmstopdir/$datadir/;
      $castorfile =~ s/$bkmstopdir/$castordir/;
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
      
      open (IN,$source) || die "$0: cannot open $source for reading: $!";
      $gstring =  <IN>;
      my $test = $gstring;    # bug fix: the bkm-file is not empty, but filled by 0 
      $test =~ s/\0//g;       # if EVB was off due to power cut.
      my $l = length($test);  # So, has to be tested.
      if(!defined($gstring) || $l == 0) {
	  print "Invalid $source file: probably empty\n";
	  print "Check if it OK in source dir, delete the empty one\n";
	  print "by hand (and restart)\n";
	  next;
      } 
      chomp($gstring);
      die "Cannot understand bkm $source" unless $gstring =~ /(\S)*/;
      $candidate = $&;
      print "gstring is $gstring\n";
      my $datasize = 0;
      my $anotherstring =  <IN>; 
      if($anotherstring =~ /size\:\s+([\d]+)/) {
	  $datasize=$1;
      }
      $anotherstring =  <IN>;
#     datetime: 13-04-14_05:15:43      
      my $thisyear;
      if($anotherstring =~ /datetime\:+\s+([\d]+)\-([\d]+)\-([\d]+)\_([\d]+):([\d]+)\:([\d]+)/) {
	  $thisyear=$3;
      }
      $thisyear=$thisyear+2000;
      close (IN);
      print "Data year: $datayear, this file taken in year: $thisyear\n";
# Check if Castor file already exists, remove it if it is old
      my @castor_stat = nsls_stat_mod($castorfile);
      my $cur_time = time();
      
  }
}



