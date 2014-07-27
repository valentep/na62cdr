#!/usr/bin/perl -w
# Author: Massimo Lamanna (Massimo.Lamanna@cern.ch) 1998-99
# Modifications Leanne Guy (Leanne.Guy@cern.ch) February 2000
# cleanup now uses the bkmcomplete directory 
# $Id: cleanup_online.pl,v 1.3 2004/05/14 14:11:09 neyret Exp $ 

require 5.004;
use strict;
use diagnostics;
use Sys::Hostname;

$SIG{USR1}=\&caught_USR;

#my($CCF_ROOT) = `grep CCF_ROOT $ENV{HOME}/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'` || "/usr/local/compass/ccf";
#defined $CCF_ROOT || die "Define CCF_ROOT enviroment variable";
# my($CCF_ROOT) = "/usr/local/compass/ccf";

my($CCF_ROOT)="/home/na62cdr/cdr";
chomp($CCF_ROOT);

require "$CCF_ROOT/toolkit/getDirMask.pl";
require "$CCF_ROOT/toolkit/ErrorReport.pl";
require "$CCF_ROOT/toolkit/bkm_dir.pl";
require "$CCF_ROOT/toolkit/miscenv.pl";

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

my($bkmrootdir,$bkmstopdir,$bkmcompletedir,$bkmsubmitdir);
my($source,$target,$gstring,$candidate);

my(@cmdarg);

# Checks/prepare bkm rootdir
$bkmrootdir = $bkm_dir;
if(!(-d $bkmrootdir)) {die "$0: bkmrootdir does not exist\n";}

# Checks/prepare bkm stopdir
# $bkmstopdir = $bkmrootdir."/OnlineTransferStop";
# if(!(-d $bkmstopdir)) {die "$0: bkmstopdir does not exist\n";}

# Checks/prepare bkm submitdir
$bkmsubmitdir = $bkmrootdir."/OnlineDataClear";
if(!(-d $bkmsubmitdir)) {die "$0: $bkmsubmitdir does not exist\n";}

# Checks/prepare bkm completedir
$bkmcompletedir = $bkmrootdir."/OnlineTransferComplete";
if(!(-d $bkmcompletedir)) {die "$0: bkmcompletedir does not exist\n";}

my $Gbs = 300;
#my $Gbs = 6500;

$hostcdr = getHost();

my $minSpaceLeft = $Gbs * 1024 * 1024;  # Free in kB

print "$0: program is starting: ".`date`;;
print "host: $hostcdr\n";
print "bkmrootdir: \t$bkmrootdir\n";
print "bkmsubmitdir: \t$bkmsubmitdir\n";
print "bkmcompletedir: $bkmcompletedir\n";
print "minSpaceLeft: \t$minSpaceLeft kBytes ($Gbs GB)\n";

my($dotcounter)=0;

my $nloop = 0;

while() {

    my $free = freeDisk(); #OR of all free disks..

    $nloop++;
    if($free && $nloop<10) { goto NEXTSLEEP;}
    $nloop = 0;

    print "Looping...  date= ".`date`;

    my(@ready) =();
    my(%ready)=();

    %ready=getDirMask("$bkmcompletedir","$bkmsubmitdir");

    print "ready candidates: ".scalar(keys(%ready))."\n";

    my %ggg=(); my $stat;
    foreach (keys %ready){
	$stat=(stat("$bkmcompletedir/$_"))[9];      # check for last modify time
	while(exists $ggg{$stat}){$stat=$stat."a"}  # should be unique !
#	print "$_ : $stat : $ready{$_}[0]\n";
	$ggg{$stat}="$_";
    }

#    print "ggg candidates: ".scalar(keys(%ggg))."\n";

#    foreach (sort{$b cmp $a} keys %ggg){            # sort in reverse time order, oldest first
    foreach (sort keys %ggg){ # sort in time order, oldest first
#	print "$ggg{$_} : $ready{$ggg{$_}}[0] : $_ \n";
	if($ready{$ggg{$_}}[0] eq "10"){push @ready,$bkmsubmitdir."/".$ggg{$_}}
    }

    %ggg=qw(); %ready=qw();
    my $nr = $#ready + 1;

    print "$nr potential candidates...\n";
    print "freeDisk reports $free\n";

    my(%diskChecked)=();

    foreach (@ready) {

	$source = $_;
	$target = $_;
#	$source =~ s/$bkmsubmitdir/$bkmstopdir/;
        $source =~ s/$bkmsubmitdir/$bkmcompletedir/;

#	print "---\n";
#	print "source $source\n";
#	print "target $target\n";
#	print "targetdir $bkmsubmitdir\n";

	if(!(-e $source)) {
	    print "---\n";
	    print "source $source\n";
	    print "target $target\n";
	    print "targetdir $bkmsubmitdir\n";
	    die "$0: Propagate error: $source";
	}

	open (IN,$source) || die "$0: cannot open $source for reading: $!";
	$gstring =  <IN>;
	chomp($gstring);
 
	if ($gstring =~ /^\s*\/[\w\/\.-]+\s+(\/[\w\/\.-]+)\s*/) {
	    $candidate = $1;
	}
	else {
	    print "Severe error?\n";
	    print "Cannot match $gstring to extract the second file (the local file)\n";
	    next;
	}

	close (IN);

#	print "Data file $candidate\n";
#	next;


	my $remove = 1;

# Some files are transferred but not cleared (bkm files)
	if(!($candidate =~ /bkm/)) {
#
# Load disk status
# apply threshold before deleting...
# note that all files are tested before
# the possibility they are on other disks
# (for which freeDisk cannot answer...)
# is taken into account (maybe paranoic...)
# Multiple freeDisk needed to avoid to delete
# *all* files from all disks if only one disk
# crosses the threshold
#
# Note that the script call freeDisk
# a first one *before* propagate/getDirMask
# to skip everything altogether if no need of 
# a cleanup is seen. Do to the primitive
# link between df-k mount points and actual
# disks, I prefer to scan all files to prevent
# "files in strange positions" to be never checked
# (see getFreeDisk logics)
#

	    my %freedisk = getFreeDisk(); #hash with mount point and free bytes

#	    print "Considering $candidate...\n";

	    $remove = 2;   # booked for deletion...
	    for (keys %freedisk) {
#print "boucle fredisk _ $_ freedisk $freedisk{$_}\n";
		if ($candidate =~ $_) {
#print "    if fredisk _ $_ freedisk $freedisk{$_}\n";

# Cancel deletion if you find the disk and this is below threshold
# Keep remove flag otherwise (notably if you do not understand the disk...)

		    if(!(defined $diskChecked{$_}[0]) ) {
# Print disk quota at first encounter...
			$diskChecked{$_}[0] = 1; 
			print "Disk = $_ has $freedisk{$_}[0] bytes ";
			print "(min $minSpaceLeft)\n";
		    }

		    $remove = 1;
		    $freedisk{$_}[0]>$minSpaceLeft && ( $remove = 0 );
		}
	    }
	    $remove==2 && print "ERROR\nERROR: no disk match...\nERROR\n";
	    $remove==1 && print "WARNING: disk is above threshold...\n";

	    @cmdarg = ("/bin/rm","-f","$candidate");
	    if($remove!=0) {		
		print "---\n";
		print "source $source\n";
		print "target $target\n";
		print "targetdir $bkmsubmitdir\n";
		print "Removing $candidate...\n";
		print "@cmdarg\n";
		unless(-e $candidate){
#		    system "touch $candidate";
		    print "LOST DATA: $candidate\n";
		    next;
		}
#		system(@cmdarg) == 0 || die "$0: @cmdarg: $!";
	    }	

	}

# BKM transfer (Stop)

	if($remove !=0) {
	
	    @cmdarg = ("cp","$source","$bkmsubmitdir");
	    print "@cmdarg\n";
#	    system(@cmdarg) == 0 || die "$0: @cmdarg: $!";

# Sleep before remove next file...
	    
	    sleep(3);

	}

    }

     if(! freeDisk()){
	 print "Cannot free disks ! Send GSM Alarm. \n";
#	 gsm_alarm("CLEANUP-ONLINE: cannot free disks !");
     }
     
NEXTSLEEP:

    $dotcounter++;
    if($dotcounter>80) {
	$dotcounter = 0;
	print "\n";
    }
    print "*";
    sleep (180);
}

sub getFreeDisk {
#    print "Disk status (/shift/$hostcdr/data__ only...): ".`date`;
    my %freedisk = ();
    my @df = `df -k /merger`;

    my $nmatch=0;

    for (@df) {
#	print "$hostcdr : $_";
#	if( /\/[a-z]+\/$hostcdr\/data\d\d/ ) {
	if( /\/merger/ ) {
	    print  "$_";
	    my $key = $&;
	    if (! (defined $freedisk{$key}[0])) {       # found new disk!
		$nmatch++;
		print  "$_";
		my @line = split(/\s+/,$_);
#		print @line;
		$freedisk{$key}[0] = $line[3];
		print $line[0],"\n";
		print $line[1],"\n";
		print $line[2],"\n";
		print $line[3],"\n";
	    }
	}
    }

    if($nmatch<=0) {
	print "Warning: no match found in freedisk...\n";
	print "Dump df -k command:\n";
	for (@df) {
	    print "$_";
	}
    }
    return %freedisk;
}

sub freeDisk {
#    print "Disk status (/shift/$hostcdr/data__ only...): ".`date`;
    my %freedisk = ();
    %freedisk = getFreeDisk();

    my $n = scalar keys %freedisk;
    if($n==0) {
	print "freedisk length is $n\n";
	return(0);
    }

    my $free = 1; # true if all disks are below threshold

    print "# minSpace=$minSpaceLeft\n#";
    for (keys %freedisk) {
	/data\d\d/ && print " $& free=$freedisk{$_}[0]";
	$freedisk{$_}[0]<$minSpaceLeft && ( $free = 0 );
    }
    print "\n";
#    for (keys %freedisk) {
#	print "Disk = $_ free=$freedisk{$_}[0] minSpace=$minSpaceLeft\n";
#	$freedisk{$_}[0]<$minSpaceLeft && ( $free = 0 );
#    }
    
    return $free;
}


sub gsm_alarm {
    my @arg = @_;
    my %arg=qw();

    foreach (@arg){ $arg{$_}=1};   # make messages unique !
    @arg=keys(%arg);

    exit if ($#arg<0); # nothing to send
    if(-e "$CCF_ROOT/sms_address.enable"){ 
        my $to_address = `cat $CCF_ROOT/sms_address.enable`;
#	my $to_address="ulrich.fuchs\@164868.gsm.cern.ch";
        chomp($to_address);
        my $subject = hostname().": @arg";
        open MAIL,"| /usr/sbin/sendmail -t -oi";
        print MAIL "From: ".hostname()." <na62cdr\@lxplus.cern.ch>\n";
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


sub caught_USR(){
    # wake up !
    print "\n\nCaught SIGUSR1 ! Waking up ..\n\n";
    sleep(2);
}
