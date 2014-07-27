#!/usr/bin/perl -w
# 

require 5.004;
use strict;
use diagnostics;
use Time::Local;
use Sys::Hostname;   # Uli

use lib '../toolkit';

my($CCF_ROOT) = `grep CCF_ROOT $ENV{HOME}/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'`;
defined $CCF_ROOT || die "Home directory CCF_ROOT not found in configuration file $ENV{HOME}/.ccfrc";
chomp($CCF_ROOT);
print "===============================================================\n";
print "===============================================================\n";
print "CCF_ROOT      ",$CCF_ROOT,"\n";

require "$CCF_ROOT/toolkit/decode_fdb_mod.pl";
require "$CCF_ROOT/toolkit/getDirMask_mod.pl";
require "$CCF_ROOT/toolkit/ErrorReport.pl";
require "$CCF_ROOT/toolkit/bkm_dir.pl";
require "$CCF_ROOT/toolkit/miscenv_mod.pl";
require "$CCF_ROOT/toolkit/ls_stat_full.pl";

sub gsm_alarm;

my($setupfile) = "$CCF_ROOT/setup/setup.dat";
my($usersfile) = "$CCF_ROOT/setup/users.dat";
#######################################################

# Get host name
my($hostcdr) = getHost();
# Check that this user is authorised to run CCF software 
my($user) = getUser_mod($usersfile);
print "Host:         $hostcdr\n";
print "User:         $user\n";
#
print "Parsing setup file: $setupfile\n";
my($datayear) = getDataYear("-quiet",$setupfile);
my($datadir) = getDataDir("-quiet",$setupfile);
print "Processing year:    $datayear\n";
print "datadir:            $datadir\n";
#
my($castordir) = getRAWrepository2("-quiet",$setupfile);

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

my($logsdir) = getLogsDir("-quiet",$setupfile);
my $statusOKFileName = "$logsdir/onl_cdr/complete_online.status.ok";
my $statusErrorFileName = "$logsdir/onl_cdr/complete_online.status.error";

my($bkm_dir);
my(@bkm_entry) = ();
my(%bkm_entry) = ();
%bkm_entry = bkm_dir("-quiet",$setupfile);

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

print "$0: starting... ".`date`;
print `uname -a`;
print "bkmstartdir:          $bkmstartdir\n";
print "bkmstopdir:           $bkmstopdir\n";
print "bkmcompletedir:       $bkmcompletedir\n";
print "castordir:            $castordir\n";
print "datadir:              $datadir\n";

my $lock_file = "$CCF_ROOT/lockfiles/complete_online.$hostcdr.lock";

while() {

    if(-e $lock_file) {
	system "touch $statusErrorFileName";
	die "Lock file found...";
    }
    print "Looping...  date= ".`date`;
    
    my %ready = ();
    my(@ready) =();

    my(%problem) = getDirMask_mod("$bkmstartdir","$bkmstopdir","$bkmcompletedir","$datadir");

    foreach (keys %problem) {
	if($problem{$_}[0] eq "1001") { # started but not stopped
	    my $problem = "$bkmstartdir/$_";
	    my $cur_time = time();
	    my $file_time = (stat($problem))[9]; # modtime
	    if(($cur_time-$file_time)>3600) { # 1 hour 
		print("remove $problem\n");
		system("rm $problem");
	    }
	}
    }

    %ready = getDirMask_mod("$bkmstartdir","$bkmstopdir","$bkmcompletedir","$datadir");

    foreach (keys %ready) {
	if($ready{$_}[0] eq "1101") {
	    push @ready,"$bkmstopdir/$_";
	}
    }

    for (@ready) {
	if(-e $lock_file) {
	    system "touch $statusErrorFileName";
	    die "Lock file found...";
	}
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

	if (defined($castor_stat[0]) && ($castor_stat[0] =~ /^\/castor\//)) {
	    if (($castor_stat[0] ne 0) && ($castor_stat[3] =~ /^m/) && ($castor_stat[1] != 0)
	        && ($disk_stat[1] == $castor_stat[1]) && ($cur_time-$castor_stat[2]) > 1800) # test migration, size, time
	    {
		my $source = $_;
		my $target = $_;
		$target =~ s/$bkmstopdir/$bkmcompletedir/;
		print("$disk_stat[0] has been migrated on tape successfully, mark it as completed.\n");
		@cmdarg = ("cp","$source","$target");
		print("@cmdarg\n");
		if(system(@cmdarg) != 0) {
		    print("Error: can't create bookmark file $target\n");
		    system("rm $target");
		    system "touch $statusErrorFileName";
		    last;
		}
	    }
	    elsif ($castor_stat[1] == 0 || $disk_stat[1] != $castor_stat[1]) # castor file size 0 or wrong size
	    {
		if (($cur_time-$file_age) > 40000) # more than 12 hours
		{
		  print("Error: Size of $disk_stat[0] = $disk_stat[1]\n       Size of $castor_stat[0] = $castor_stat[1]\n");
		  # Error recovery:
		  print("Remove bkm files: $stop_file and $start_file\n");
		  gsm_alarm("Bad castor file size for $disk_stat[0] ($disk_stat[1] against $castor_stat[1])\n");
		  system("rm $stop_file");
		  system("rm $start_file");
		  print("Remove Castor file: $castor_stat[0]\n");
		  system("rfrm $castor_stat[0]");
		  system "touch $statusErrorFileName";
		}
	    }
	    elsif(($castor_stat[3] =~ /^\-/) && ($castor_stat[0] ne 0))   
#Not yet the "m" in the castor nsls -l output (not on tape but only on castor disks
	    {
		if(($cur_time-$file_age) > 40000) # more than 12 hours
		{
		    system "touch $statusErrorFileName";
		    print("WARNING: File $castor_stat[0] still not migrated to tape.\n");
		}
	    }
	}
	system "touch $statusOKFileName";
	print "DEBUG remember to remove sleep\n";
	sleep 10;
    }
    system "touch $statusOKFileName";
    print("Sleep 2 minutes before next cicle...\n");
    sleep 120;
}


sub gsm_alarm {   # Uli

    my @arg = @_;

    if(-e "$CCF_ROOT/sms_address.enable") {

#         my $to_address = "vladimir.frolov\@163466.gsm.cern.ch"; #`cat $CCF_ROOT/sms_address.enable`;
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
