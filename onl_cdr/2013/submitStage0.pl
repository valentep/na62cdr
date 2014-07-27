#!/usr/bin/perl -w

# test script for CASTOR 2, DN 26/3/2007
# Steer an optional dump into CASTOR
# Author: Felice Pantaleo (felice.pantaleo@cern.ch), Massimo Lamanna
# $Id: submitStage0.pl,v 1.11 2012/10/26 17:37:45 neyret Exp $

require 5.004;
use strict;
use diagnostics;

my $year = 2012;

my $HOME = "/home/na62cdr/cdr";

#my($CCF_ROOT) = `grep CCF_ROOT $ENV{HOME}/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'` || "/usr/local/compass/ccf";
my($CCF_ROOT) = "/home/na62cdr/cdr";
#defined $CCF_ROOT || die "Define CCF_ROOT enviroment variable";
#chomp($CCF_ROOT);

$ENV{RAWDATAMIGR_TIMEOUT} = 1800;

# force rfcp and other rf* commands to follow Castor-2 protocols
$ENV{RFIO_USE_CASTOR_V2}  = "YES";

# define Castor-2 stager, and service class (= disk pool)
$ENV{STAGE_HOST}  = "castorpublic";
$ENV{STAGE_SVCCLASS}  = "na62";
$ENV{STAGE_POOL}  = "na62";

my $rawdatamigr = "rfcp";


unless(defined($ENV{LD_LIBRARY_PATH})) {
    $ENV{LD_LIBRARY_PATH}  = "$HOME/bin";
}

unless($ENV{LD_LIBRARY_PATH} =~ /\/usr\/local\/lib/) {
    $ENV{LD_LIBRARY_PATH}  = "$ENV{LD_LIBRARY_PATH}:$HOME/bin";
}

require "$CCF_ROOT/toolkit/decode_fdb.pl";
require "$CCF_ROOT/toolkit/bkm_dir.pl";
require "$CCF_ROOT/toolkit/miscenv.pl";
require "$CCF_ROOT/toolkit/getDirMask.pl";

# CCF modules loading
#use FindBin qw($Bin);
#use lib "$Bin/../toolkit";
use lib "/home/na62cdr/cdr/toolkit";
use lib '../toolkit';
use Time::Local;
use CCFprint;
use Sys::Hostname;   # Uli

#my($host) = getHost();
my($host) = "na62merger";
my(@bkm_entry) = ();
my(%bkm_entry) = ();
%bkm_entry = bkm_dir("-quiet","$CCF_ROOT/setup/setup.dat");
my $statusOKFileName = "/merger/logs/onl_cdr/submitStage0.status.ok";
my $statusErrorFileName = "/merger/logs/onl_cdr/submitStage0.status.error";

my($bkm_dir);

foreach  (sort keys %bkm_entry) {
  if ( $host = $_) { $bkm_dir = $bkm_entry{$_}; }
}

die "$0: No bkm_dir on this host ($host). Check the setup.dat file..." unless defined($bkm_dir);

my($bkmrootdir,$bkmstopdir,$bkmsubmitdir);
my($source,$target,$gstring,$candidate,$disk_file,$castorfile);

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

my($wait0) = 60; # ML 21-5-1999
my($wait1) =  5; # ML 21-5-1999

# Check that this user is authorised to run CCF software 
my($user) = getUser();

my($castordir) = getRAWrepository2("-quiet","$CCF_ROOT/setup/setup.dat");
my($datadir)        = "/merger/cdr";

$host = getHost();

infoPrint;
print "host:         $host\n";
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

while() {

    if(-e $lock_file) {
	system "touch $statusErrorFileName";
	die "Lock file found...";
    }

    my %ready = ();
    my(@ready) =();

    %ready = getDirMask("$bkmstopdir","$bkmsubmitdir","$bkmenddir");
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
 
    system "touch $statusOKFileName";
    print "submitStage0.pl: Before next cycle... sleep $waittime s\n";
    sleep($waittime);
    print "Looping...  date= ".`date`;

    my($nfile)=0;
    my($totape) = "";
    my($kfile)=0;

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

      close (IN);


# Check if Castor file already exists, remove it if it is old

      my @castor_stat = nsls_stat($castorfile);
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
	  system("rm $target");
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
  }

dot60;

}




sub gsm_alarm {   # Uli

    my @arg = @_;

    if(-e "$CCF_ROOT/sms_address.enable") {

        my $to_address = `cat $CCF_ROOT/sms_address.enable`;
        chomp($to_address);
        my $subject = hostname().": @arg";

	open MAIL,"| /usr/sbin/sendmail -t -oi";
        print MAIL "To: $to_address \n";
        print MAIL "Subject: $subject \n";
        print MAIL "\n";
        print MAIL "No message body to be sent along with GSM\n";
        close MAIL;

        print "gsm_alarm: sms sent: $subject\n";
    }
    else {
        print "gsm_alarm: sms disabled\n";
    }

}


sub nsls_stat {
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


    print("nsls_ret: $nsls_ret\n");
    if($nsls_ret =~ /([\S]+)\s+([\S]+)\s+([\S]+)\s+([\S]+)\s+([\d]+)\s+([\S]+)\s+([\d]+)\s+([\d]+)\:([\d]+)\s+([\S]+)/) {
	my $fperm = $1;
	my $fnumb = $2;
	my $owner = $3;
	my $group = $4;
	my $fsize = $5;
#	my $ftime = timelocal(0,$9,$8,$7,$months{$6},$year,0,0,0);

	my $month = $months{$6};
	my $ftime = timegm(0,$9,$8,$7,$month,$year);

	my $fname = $10;
	@ret_stat = ($fname,$fsize,$ftime,$fperm);	
    }
#    print("ret_stat[0] = $ret_stat[0]\n");
    return @ret_stat;
}


