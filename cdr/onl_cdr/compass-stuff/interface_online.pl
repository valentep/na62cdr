#!/usr/bin/perl -w
# Author: Massimo Lamanna (Massimo.Lamanna@cern.ch)
#     and Ulrich Fuchs (Ulrich Fuchs@cern.ch) June 2000

require 5.004;
use strict;
use diagnostics;

$SIG{USR1}=\&caught_USR;

#my($CCF_ROOT) = `grep CCF_ROOT $ENV{HOME}/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'` || "/usr/local/compass/ccf";
my($CCF_ROOT) = "/home/na62cdr/cdr";
defined $CCF_ROOT || die "Define CCF_ROOT enviroment variable";
chomp($CCF_ROOT);
my $statusOKFileName = "/merger/logs/onl_cdr/interface_online.status.ok";
my $statusErrorFileName = "/merger/logs/onl_cdr/interface_online.status.error";


require "$CCF_ROOT/toolkit/bkm_dir.pl";
require "$CCF_ROOT/toolkit/miscenv.pl";

sub getoldname;

my($host) = getHost();

my(@bkm_entry) = ();
my(%bkm_entry) = ();
%bkm_entry = bkm_dir("-quiet","$CCF_ROOT/setup/setup.dat");


my($bkmrootdir);
# for  (@bkm_dir) {
#     /$host/ && ($bkmrootdir = $_);
# }
# die "$0: No bkmrootdir on this host ($host). Check the setup.dat file..." unless defined($bkmrootdir);
#my($tsthost);
#my($tstbkmrootdir);
foreach  (sort keys %bkm_entry) {
  if ( $host = $_) { $bkmrootdir = $bkm_entry{$_}; }
}

die "$0: No bkmrootdir on this host ($host). Check the setup.dat file..." unless defined($bkmrootdir);

# Check that this user is authorised to run CCF software 
my($user) = getUser();

my($bkmsubmitdir,$bkmcompletedir);

my($source,$target,$gstring,$candidate);

# Checks/prepare bkm rootdir 
if(!(-d $bkmrootdir)) {die "$0: bkmrootdir $bkmrootdir does not exist\n";}

# Checks/prepare bkm complete dir
$bkmcompletedir = $bkmrootdir."/OnlineDataComplete";
if(!(-d $bkmcompletedir)) {die "$0: bkmcompletedir does not exist\n";}

# Checks/prepare bkm submitdir
$bkmsubmitdir = $bkmrootdir."/OnlineDataStop";
if(!(-d $bkmsubmitdir)) {die "$0: bkmsubmitdir does not exist\n";}

$host = getHost();

print "$0: program is starting... ".`date`;
print "host: $host\n";
print "bkmsubmitdir: $bkmsubmitdir\n";
print "bkmcompletedir: $bkmcompletedir\n";

my($dotcounter)=0;

while() {

    if(-e "$CCF_ROOT/lockfiles/interface_online.$host.lock") {
	system "touch $statusErrorFileName";
        die "Lock file found...";
    }

    print "Looping...  date= ".`date`;

    my(@ready);

# Unitarity (checksum) files

    @ready = getMissingBKM($bkmsubmitdir,$bkmcompletedir);

    print("@ready\n");

    for (@ready) {


	$source = "$bkmsubmitdir/$_";
	$target = "$bkmcompletedir/$_";
	print "\n\n\n===== New file to treat (from missing BKM) ===\n";
	print "`date +\"%d %b %Y %H:%M:%S\"`\n";
	print "source $source\n";
	print "target $target\n";
	
	if(!(-e $source)) {
	    system "touch $statusErrorFileName";
	    die "$0: from getMissingBKM error: $source";
	}

#	open (IN,$source) || die "$0: cannot open $source for reading: $!";
#	$gstring =  <IN>;
#	close (IN);
#	chomp($gstring);

	$gstring = `cat $source`;

	print "transfer candidate $source\n";
	print "targetname $target\n";
	print "old bkm contains: $gstring\n";

	$gstring =~ s/\n/ /g;
	$gstring =~ s/\/[\w\d\/]+\///g;
	$gstring =~ s/cdr//g;
	$gstring =~ s/\.raw//g;
	$gstring =~ s/-\d{5,6}_//g;
	$gstring =~ s/Receivers://;

	$gstring = $target." Receivers: ".$gstring;

	print "new bkm contains: $gstring\n";

	if(-e $target) {
	    system "touch $statusErrorFileName";
	    die "$0: Severe error: file $target already existing";
	}

	open (IN,">$target") || die "$0: cannot open $target for writing: $!";
	print IN $gstring;
	close (IN);
	
    }

# CDR files...
    
    @ready = getMissingCDR($bkmsubmitdir,$bkmcompletedir);

    my($sleep) = $#ready+1;
#    $sleep = int($sleep*$sleep/10);
#    $sleep = int($sleep*$sleep/2) + 1;
#    $sleep<=0 && ($sleep=10);
#    $sleep>100 && ($sleep=100);
    $sleep = 1;
    
    for (@ready) {

	$source = "$bkmsubmitdir/".getoldname($_);
	$target = "$bkmcompletedir/$_";
        
	print "\n\n\n===== New file to treat (from missing CDR) ===\n";
	print `date +\"%d %b %Y %H:%M:%S\"`;
	print "\nsource $source\n";
	print "target $target\n";
	
	if(!(-e $source)) {print  "$0: from getMissingCDR error: $source"; next;}

	open (IN,$source) || die "$0: cannot open $source for reading: $!";
	$gstring =  <IN>;
	close (IN);

	if(!defined $gstring) {
	    print "$0: empty $source ?!";
	    next;
	}
	chomp($gstring);

	if( $gstring =~ /(\S)*/ ) {
	    $candidate = $&;
	}
	else {
	    die "$0: Severe error: cannot find a candidate out of $gstring";
	}

	if(!(-e $candidate)) {
	    print "$0: Severe error: cannot find $candidate";
	    next;
	}

	my($dest_file) = $candidate;
	$dest_file =~ /\/.*\//;
	$dest_file = $&.$_;

	print "transfer candidate $candidate\n";
	print "targetname $dest_file\n";
	print "old bkm contains: $gstring\n";
	$gstring = $dest_file." ".$gstring;
	print "new bkm contains: $gstring\n";

	if(-e $dest_file) {die "$0: Severe error: file $dest_file already existing";}
###	system("mv $candidate $dest_file");
	rename "$candidate","$dest_file" || die 
	    "$0: Severe error: cannot move $candidate onto $dest_file: $!"; #Does not die...

	open (IN,">$target") || die "$0: cannot open $target for writing: $!";
	print IN $gstring;
	close (IN);

	print "$0: sleep $sleep\n";
	system "touch $statusOKFileName";
	sleep($sleep);

    }

# Sleep
    $dotcounter++;
    if($dotcounter>60) {
	$dotcounter = 0;
	print "\n";
    }
    print ".\n";
    system "touch $statusOKFileName";
    sleep(20);

}

sub getMissingCDR {

    my($in,$out) = @_;

    my(@in)  = ();
    my(@out) = ();

    my($item);
    
# print "getMissingCDR: input $in , $out\n";

#
# Load a list of all existing file in the source directory
#

    opendir SOURCEDIR, $in or die "$in not defined: $!";
    
    while(  defined( $item = readdir SOURCEDIR) ) {

	next if($item=~/xxx/); # added by Uli

	getnewname($item) ne "" && push @in,getnewname($item);
    }
    
    closedir SOURCEDIR;

#
# Load a list of all existing file in the target directory
#

    opendir TARGETDIR, $out or die "$in not defined: $!";
    
    while(  defined( $item = readdir TARGETDIR) ) {
	    push @out,$item;
    }
    
    closedir TARGETDIR;
 
# see Perl Cookbook p.104
    my %seen;    # lookup table
    my @missing; # answer

    @seen{@out} = ();

    foreach $item (@in) {
	push (@missing, $item) unless exists $seen{$item};
    }

    return @missing;

}

sub getMissingBKM {

    my($in,$out) = @_;

    my(@in)  = ();
    my(@out) = ();

    my($item);
    
#print "getMissingBKM: input $in , $out\n";

#
# Load a list of all existing file in the source directory
#

    opendir SOURCEDIR, $in or die "$in not defined: $!";
    
    while(  defined( $item = readdir SOURCEDIR) ) {
	$item=~/^cdr\d{3,6}$/ && push @in,$item;
    }
    
    closedir SOURCEDIR;

#
# Load a list of all existing file in the target directory
#

    opendir TARGETDIR, $out or die "$in not defined: $!";
    
    while(  defined( $item = readdir TARGETDIR) ) {
	$item=~/^cdr\d{3,6}/ && push @out,$item;
    }
    
    closedir TARGETDIR;

#for (@in){print "getMissingBKM in: $_\n";}
#for (@out){print "getMissingBKM out: $_\n";}
 
# see Perl Cookbook p.104
    my %seen;    # lookup table
    my @missing; # answer

    @seen{@out} = ();

    foreach $item (@in) {
	push (@missing, $item) unless exists $seen{$item};
    }

for (@missing){print "getMissingBKM missing: $_\n";}

    return @missing;

}

sub getnewname(){
# change filenames from 'LARS' format to 'CCF' format
# LARS: cdr11-22222_333.raw
# CDR: cdr11333-22222.dat

  my($newname)="";

  if ($_[0]=~/^cdr(\d+)-(\d+)_(\d+).raw/){  # cdr11-22222_333.raw
    $newname="cdr".$1.$3."-".$2.".dat";
  }
#   elsif($_[0]=~/^cdr(\d+)-(\d+).raw/){      # cdr11-22222.raw
#     $newname="cdr".$1."000-".$2.".dat";
#   }
  elsif ($_[0]=~/^cdrna62merger(\d+)-(\d+)\.(\d+)\.raw/){  # cdrna62merger11-22222.333.raw
    $newname="cdr".$1.$3."-".$2.".dat";
  }
  elsif($_[0]=~/^cdrna62merger(\d+)-(\d+)\.raw/){      # cdrna62merger11-22222.raw
    $newname="cdr".$1."-".$2.".dat";
  }
  return $newname;
}

sub getoldname {
# almost -1 of getnewname...

  my($newname)="";

#   if ($_[0]=~/^cdr(\d{2,2})(\d{3,3})-(\d{5,5}).dat/){  # cdr11-22222_333.dat
#     $newname="cdr".$1."-".$3."_".$2.".raw";
#   }
#   elsif($_[0]=~/^cdr(\d{2,2})-(\d{5,5}).dat/){      # cdr11-22222.dat
#     $newname="cdr".$1."-".$2.".raw";
#   }
  my($ebtype)="na62merger";
# no more ecal tests, removed
#  if ($host eq "pccoeb16") { $ebtype = "pccorb"; } # for ecal tests, not beautifull but...

  if ($_[0]=~/^cdr(\d{2,2})(\d{3,3})-(\d{3,6})\.dat/){  # cdrpccoeb11-22222.333.raw
    $newname="cdr$ebtype".$1."-".$3.".".$2.".raw";
  }
  elsif($_[0]=~/^cdr(\d{2,2})-(\d{3,6})\.dat/){      # cdrpccoeb11-22222.raw
    $newname="cdr$ebtype".$1."-".$2.".raw";
  }
  return $newname;
}


sub caught_USR(){
    # wake up !
    print "\n\nCaught SIGUSR1 ! Waking up ..\n\n";
    sleep(2);
}