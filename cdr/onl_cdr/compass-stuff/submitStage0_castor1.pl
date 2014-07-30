#!/usr/bin/perl -w

# Steer an optional dump into CASTOR
# Author: Massimo Lamanna (Massimo.Lamanna@cern.ch) 2000
# $Id: submitStage0.pl,v 1.11 2006/02/02 17:37:45 neyret Exp $

require 5.004;
use strict;
use diagnostics;

#my($CCF_ROOT) = `grep CCF_ROOT $ENV{HOME}/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'` || "/usr/local/compass/ccf";
my($CCF_ROOT) = "/home/na62cdr/cdr";
#defined $CCF_ROOT || die "Define CCF_ROOT enviroment variable";
#chomp($CCF_ROOT);

$ENV{STAGE_HOST}  = "stagecompass";
$ENV{STAGE_POOL}  = "compasscdr1";
$ENV{RAWDATAMIGR_TIMEOUT} = 1800;

unless(defined($ENV{LD_LIBRARY_PATH})) {
    $ENV{LD_LIBRARY_PATH}  = "/online/detector/cdr/bin";
}

unless($ENV{LD_LIBRARY_PATH} =~ /\/usr\/local\/lib/) {
    $ENV{LD_LIBRARY_PATH}  = "$ENV{LD_LIBRARY_PATH}:/online/detector/cdr/bin";
}

require "$CCF_ROOT/toolkit/decode_fdb.pl";
require "$CCF_ROOT/toolkit/bkm_dir.pl";
require "$CCF_ROOT/toolkit/miscenv.pl";
require "$CCF_ROOT/toolkit/getDirMask.pl";

# CCF modules loading
#use FindBin qw($Bin);
#use lib "$Bin/../toolkit";
use lib "/online/detector/cdr/toolkit";
use lib '../toolkit';
use CCFprint;
use Sys::Hostname;   # Uli

my($host) = getHost();

# my %stage_pools = qw(
# 		     pccoeb09   compasscdr1
# 		     pccoeb10   compasscdr2
# 		     pccoeb11   compasscdr3
# 		     pccoeb12   compasscdr4
# 		     pccoeb13   compasscdr1
# 		     pccoeb14   compasscdr2
# 		     pccoeb15   compasscdr3
# 		     pccoeb16   compasscdr4
# 		     pccoeb17   compasscdr1
# 		     pccoeb18   compasscdr2
# 		     pccoeb19   compasscdr3
# 		     pccoeb20   compasscdr4
# 		     pccoeb21   compasscdr1
# 		     pccoeb22   compasscdr2
# 		     pccoeb23   compasscdr3
# 		     pccoeb24   compasscdr4
# 		     pccoeb25   compasscdr1
# 		     pccoeb26   compasscdr2
# 		     pccoeb27   compasscdr3
# 		     pccoeb28   compasscdr4
# 		     pccoeb29   compasscdr1
# 		     pccoeb30   compasscdr2
# 		     pccoeb31   compasscdr3
# 		     pccoeb32   compasscdr4
# 		     pccoeb33   compasscdr1
# 		     );


my %stage_pools = qw(
		     pccoeb09   compasscdr1
		     pccoeb10   compasscdr2
		     pccoeb11   compasscdr3
		     pccoeb12   compasscdr4
		     pccoeb13   compasscdr1
		     pccoeb14   compasscdr2
		     pccoeb15   compasscdr3
		     pccoeb16   compasscdr4
		     pccoeb17   compasscdr1
		     pccoeb18   compasscdr2
		     pccoeb19   compasscdr3
		     pccoeb20   compasscdr4
		     pccoeb21   compasscdr1
		     pccoeb22   compasscdr2
		     pccoeb23   compasscdr3
		     pccoeb24   compasscdr4
		     pccoeb25   compasscdr1
		     pccoeb26   compasscdr2
		     pccoeb27   compasscdr3
		     pccoeb28   compasscdr4
		     pccoeb29   compasscdr1
		     pccoeb30   compasscdr2
		     pccoeb31   compasscdr3
		     pccoeb32   compasscdr4
		     pccoeb33   compasscdr1
		     );

$ENV{STAGE_POOL} = $stage_pools{$host};                             

# my(@bkm_dir) = bkm_dir("-quiet","$CCF_ROOT/setup/setup.dat");
my(@bkm_entry) = ();
my(%bkm_entry) = ();
%bkm_entry = bkm_dir("-quiet","$CCF_ROOT/setup/setup.dat");

my($bkm_dir);
#for  (@bkm_dir) {
#    /$host/ && ($bkm_dir = $_);
#}
foreach  (sort keys %bkm_entry) {
  if ( $host = $_) { $bkm_dir = $bkm_entry{$_}; }
}

die "$0: No bkm_dir on this host ($host). Check the setup.dat file..." unless defined($bkm_dir);

my($bkmrootdir,$bkmstopdir,$bkmsubmitdir);
my($source,$target,$gstring,$candidate);

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

my($wait0) = 120; # ML 21-5-1999
# my($wait1) =  30; # ML 21-5-1999
my($wait1) =  5; # ML 21-5-1999

# Check that this user is authorised to run CCF software 
my($user) = getUser();

my($castordir) = getRAWrepository("-quiet","$CCF_ROOT/setup/setup.dat");

$host = getHost();

infoPrint;
print "host:         $host\n";
print "bkmrootdir:   $bkmrootdir\n";
print "bkmstopdir:   $bkmstopdir\n";
print "bkmsubmitdir: $bkmsubmitdir\n";
print "bkmenddir:    $bkmenddir\n";
print "castordir:    $castordir\n";

my $lock_file = "$CCF_ROOT/lockfiles/submitStage0_castor1.$host.lock";

my $num_candidate = 0; # counter of candidates for selecting fraction of them to be staged to compass_anal as well

while() {

    if(-e $lock_file) {
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

###    push  @ready,"/shift/ccf009d/data01/objsrvvy/bkm/DumpTransferStart/cdr01002-05358.dat";

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
 
    print "submitStage0.pl: Before next cycle... sleep $waittime s\n";
    sleep($waittime);
    print "Looping...  date= ".`date`;

    my($nfile)=0;
    my($totape) = "";
    my($kfile)=0;

    for (@ready) {

      if(-e "$lock_file") {
	die "Lock file found...";
      }

#      print "$_\n";
#      die" UUU";
#      next unless (/cdr16007\-27540/);
#      print "ready to start...";
#      sleep 10;

	$lastsearch = 0;
	$source = $_;
	$target = $_;
	$target =~ s/$bkmstopdir/$bkmsubmitdir/;

	my $newdate = `date +\"%d %b %Y %H:%M:%S\"`;
	my $newseconds = `date +\"%s\"`;

	print "===============================================================\n\n";
	print "*** Reading new file ***\n\n";
	print "$newdate\n";
	print "\nsource:       $source\n";
	print "target:       $target\n";
	print "targetdir:    $bkmsubmitdir\n";

	if(!(-e $source)) {die "$0: Propagate error: $source";}

	open (IN,$source) || die "$0: cannot open $source for reading: $!";
	$gstring =  <IN>;
        if(!defined($gstring)) {
	    print "Invalid $source file: probably empty\n";
	    print "Check if it OK in source dir, delete the empty one\n";
	    print "by hand (and restart)\n";
	    next;
        } 
      chomp($gstring);

      die "Cannot understand bkm $source" unless $gstring =~ /(\S)*/;
      $candidate = $&;

      close (IN);

# Dump transfer start

      my($fname) = $candidate;
      die "Cannot extract filename for $candidate" 
	  unless $fname =~ /\/(cdr(\d{5,5}-){0,1}\d{5,5}(\.dat){0,1})/ ||
	         $fname =~ /\/(cdr(\d{2,2}-){0,1}\d{5,5}(\.dat){0,1})/;
      $fname = $1;

      if(!(defined $fname)) {
	  print "$0: transfer candidate filename failure; skip...\n";
	  next;
      }

      print "transfer candidate $candidate\n";

# BKM Start
      @cmdarg = ("cp","$source","$bkmsubmitdir");
      print ("@cmdarg\n");
      system(@cmdarg) == 0 || die "$0: @cmdarg: $!";
      system("ls -l $bkmsubmitdir/$fname");

# Data transfer
#  following line has been commented by V.Frolov 25/09/2003:
#  uncommented by D.Neyret 21/4/2004
      @cmdarg = ("time","/online/detector/cdr/bin/rawdatamigr","$candidate","$castordir");

#  25/09/2003:  just copy data file to castor without producing meta-data:
#  21/4/2004: back to the normal behaviour
#      @cmdarg = ("time","/usr/local/bin/rfcp","$candidate","$castordir");

      print ("command to launch: @cmdarg\n");
#      system("printenv");
      my $execresult = system(@cmdarg);

      print "$0: rawdatamigr return code: $execresult\n";
      if($execresult==1536) { # Command terminated by signal 6
	  system("echo \"$candidate transfer is terminated by signal 6\" >> /tmp/ccf/cdr/error.log");
	  print("copy file $candidate by rfcp\n");
	  $execresult = system("/usr/bin/rfcp $candidate $castordir");
      }
      unless($execresult==0){
	  system("rm $target");
	  next;
      }

# Data transfer to compass_anal for online analysis
# added by Antonin Kral, 22.10.2004

#    my $old_stage_pool_env = $ENV{STAGE_POOL};
#    $ENV{STAGE_POOL} = 'compass_anal';

#    $num_candidate++;
#    if ($num_candidate == 4){
#      $execresult = system("/usr/bin/stagein --nowait --rdonly -M $castordir/$candidate");
#      unless ($execresult == 0){
#        system("echo \"WARNING: unable to stagein $candidate to compass_anal\" >> /tmp/ccf/cdr/error.log");
#        print "WARNING: unable to stagein $candidate to compass_anal\n";
#      }
#    } else {
#      if ($num_candidate > 4) { $num_candidate=0; }
#    }

#    $ENV{STAGE_POOL} = $old_stage_pool_env;

# end of compass_anal

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
    

    if(!(-e $source)) {die "$0: Propagate error: $source";}
#      system("touch /online/detector/cdr/lockfiles/submitStage0.lock");
#    print "Old bkm contains: $gstring\n";
    $gstring = "$castordir/$fname $gstring";
#    print "New bkm contains: $gstring\n";
    
# BKM Stop
    open (OUT,">$target") || die "$0: cannot open $target for writing: $!";
    print OUT $gstring;
    close (OUT);
    
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


