#!/usr/bin/perl -w
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
require "$CCF_ROOT/toolkit/getDirMask.pl";
require "$CCF_ROOT/toolkit/ErrorReport.pl";
require "$CCF_ROOT/toolkit/bkm_dir.pl";
require "$CCF_ROOT/toolkit/miscenv.pl";

sub gsm_alarm;
sub nsls_stat;

$ENV{STAGE_HOST}  = "castorpublic";
$ENV{STAGE_SVCCLASS}  = "na62";
$ENV{STAGE_POOL}  = "na62";
$ENV{RFIO_USE_CASTOR_V2}  = "YES";
my $statusOKFileName = "/merger/logs/onl_cdr/complete_online.status.ok";
my $statusErrorFileName = "/merger/logs/onl_cdr/complete_online.status.error";


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

my $year = 2012;

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

    if(-e "$CCF_ROOT/lockfiles/complete_online.$hostcdr.lock") {
	system "touch $statusErrorFileName";
	die "Lock file found...";
    }

    print "Looping...  date= ".`date`;

    # Create the files' bitmaps

    my %ready = ();
    my(@ready) =();

    my(%problem) = getDirMask("$bkmstartdir","$bkmstopdir","$bkmcompletedir","$datadir");

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

    %ready = getDirMask("$bkmstartdir","$bkmstopdir","$bkmcompletedir","$datadir");

    foreach (keys %ready) {
	if($ready{$_}[0] eq "1101") {
	    push @ready,"$bkmstopdir/$_";
	}
    }

    for (@ready) {
	if(-e "$CCF_ROOT/lockfiles/complete_online.$hostcdr.lock") {
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
#	$castorfile =~ s/\.dat/\.raw/;

	my @disk_stat = ls_stat($disk_file);
	my @castor_stat = nsls_stat($castorfile);
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

sub nsls_stat {
    my @arg = @_;
    my @ret_stat = ();
    my $nsls_ret = `/usr/bin/nsls -l $arg[0]`;
    if($nsls_ret =~ /([\S]+)\s+([\S]+)\s+([\S]+)\s+([\S]+)\s+([\d]+)\s+([\S]+)\s+([\d]+)\s+([\d]+)\:([\d]+)\s+([\S]+)/) {
	my $fperm = $1;
	my $fnumb = $2;
	my $owner = $3;
	my $group = $4;
	my $fsize = $5;
	my $ftime = timelocal(0,$9,$8,$7,$months{$6},$year,0,0,0);
	my $fname = $10;
	@ret_stat = ($fname,$fsize,$ftime,$fperm);	
    }
    return @ret_stat;
}

sub ls_stat {
    my @arg = @_;
    my @ret_stat = ();
    my $nsls_ret = `ls -l $arg[0]`;
    if($nsls_ret =~ /([\S]+)\s+([\S]+)\s+([\S]+)\s+([\S]+)\s+([\d]+)\s+([\S]+)\s+([\d]+)\s+([\d]+)\:([\d]+)\s+([\S]+)/) {
	my $fperm = $1;
	my $fnumb = $2;
	my $owner = $3;
	my $group = $4;
	my $fsize = $5;
	my $ftime = timelocal(0,$9,$8,$7,$months{$6},$year,0,0,0);
	my $fname = $10;
	@ret_stat = ($fname,$fsize,$ftime,$fperm);	
    }
    return @ret_stat;
}
