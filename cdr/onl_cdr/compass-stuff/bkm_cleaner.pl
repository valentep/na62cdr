#!/usr/bin/perl -w
# $Id: bkm_cleaner.pl,v 1.2 2006/02/02 17:37:45 neyret Exp $

require 5.004;
use strict;
use diagnostics;

use File::Copy;
sub cof_take_care;

my($CCF_ROOT)="/home/na62cdr/cdr/cdr";
defined $CCF_ROOT || die "Define CCF_ROOT enviroment variable";
chomp($CCF_ROOT);

$ENV{RFIO_USE_CASTOR_V2} = "YES";
$ENV{STAGE_HOST}  = "castorpublic";
$ENV{STAGE_SVCCLASS}  = "compasscdr";

require "$CCF_ROOT/toolkit/bkm_dir.pl";
require "$CCF_ROOT/toolkit/miscenv.pl";
require "$CCF_ROOT/toolkit/getDirMask.pl";

print("\n\n\t\t*********\n");
system("date");
print("\n");

my($datadir)        = "/merger/cdr";

my($hostcdr) = getHost();

my $cur_date = `date +%y%m%d-%H%M%S`;
chomp($cur_date);
my $exec_code = system("cd /home/na62cdr/cdr/cdr/onl_cdr/ ; ./stop.sh");

if($exec_code != 0) { die "Cannot stop CDR.\n"; }

my $counter = 0;

while($exec_code == 0) {
    sleep(10);
    my $perl_ps = `ps -u objsrvvy -o command --columns 255 | grep perl | wc -l`;
#    print("n procs: $perl_ps\n");
    if($perl_ps <= 3) { $exec_code = 1; }
    $counter++;
    if($counter > 100) { die "Cannot stop CDR. Timeout error.\n"; }
}

my(@bkm_entry) = ();
my(%bkm_entry) = ();
%bkm_entry = bkm_dir("-quiet","$CCF_ROOT/setup/setup.dat");

my($bkm_dir);

foreach  (sort keys %bkm_entry) {
  if ( $hostcdr = $_) { $bkm_dir = $bkm_entry{$_}; }
}

die "$0: No bkm_dir on this host ($hostcdr). Check the setup.dat file..." unless defined($bkm_dir);


my $bkmbackup="/tmp/bkm";

my(@dir) = ("$bkmbackup/OnlineDataStop",
	    "$bkmbackup/OnlineDataComplete",
	    "$bkmbackup/OnlineTransferStart",
	    "$bkmbackup/OnlineTransferStop",
	    "$bkmbackup/OnlineTransferComplete",
	    "$bkmbackup/OnlineDataClear",
	    );
foreach (@dir){
    system "mkdir -p $_" unless(-d $_);
}

my(%run) = getDirMask(
		      "$bkm_dir/OnlineDataComplete",
		      "$bkm_dir/OnlineTransferStart",
		      "$bkm_dir/OnlineTransferStop",
		      "$bkm_dir/OnlineTransferComplete",
		      "$bkm_dir/OnlineDataClear",
		      "$datadir",
		      );
my $i=0;
$hostcdr = getHost();
foreach (keys %run) {
    if( $run{$_}[0] eq "111110" ) {
	$i++;
	my $a=`cat $bkm_dir/OnlineTransferStart/$_`;
	my $cof_data="";
	if($a =~ /^(\/[\w\/\d\-\.]+)\s+(\/[\w\/\d\-\.]+)\s+/){
	    $cof_data=$2;
	    if(-e $cof_data){
		print "COF Data still there: $cof_data!\n";
		next;
	    }
	}else{
	    die "Found invalid bookmark !\n$_\n";
	}
#	die "COF Data still there !\n" if(-e $cof_data); 	
	cof_take_care($_);
    }
}
print("$i bkm-files have been moved\n");

$hostcdr = getHost();
my $backup_file = "${hostcdr}_${cur_date}.tgz";

$exec_code = system("cd /tmp/ ; tar cf - ./bkm | gzip -c > $backup_file");
if($exec_code != 0) { die "Tar error.\n"; }

my $backup_dir = "/castor/cern.ch/user/o/objsrvvy/bkm/";

$exec_code = system("cd /tmp/ ; /usr/bin/rfcp ./$backup_file $backup_dir");
if($exec_code != 0) { die "rfcp error.\n" }

$exec_code = system("cd /tmp/ ; rm -rf ./bkm");
if($exec_code != 0) { die "Cannot remove BKM files from the disk.\n" }

$exec_code = system("cd /online/detector/cdr/onl_cdr/ ; ./start.sh");
if($exec_code != 0) { die "Cannot start CDR.\n"; }

print("OK!\n");


sub cof_take_care {
# 0: name
    
    my @rem=();
    my $old=getoldname($_[0]);

    push @rem, "OnlineDataStop/$old";
    push @rem, "OnlineDataComplete/$_[0]", "OnlineTransferStart/$_[0]";
    push @rem, "OnlineTransferStop/$_[0]", "OnlineTransferComplete/$_[0]";
    push @rem, "OnlineDataClear/$_[0]";
    foreach (@rem){
#	print "$i: move $bkm_dir/$_ -> $bkmbackup/$_ \n";
	copy "$bkm_dir/$_","$bkmbackup/$_" || die "Cannot copy $_ \n";
	unlink "$bkm_dir/$_"               || die "Cannot unlink $_ \n";
    }
    if(($i % 100) == 0) {
	print("$i\n");
    }
}


sub getoldname(){
# LARS: cdr11-22222_333.raw
# CDR: cdr11333-22222.dat

  my($newname)="";
  if ($_[0]=~/^cdr(\d{2})(\d{3})-(\d{3,6}).dat/){  # cdr11-22222_333.raw
#    $newname="cdr".$1."-".$3."_".$2.".raw";
    $newname="cdrpccoeb".$1."-0".$3.".".$2.".raw";
  }
  elsif($_[0]=~/^cdr(\d{2})-(\d{3,6}).dat/){      # cdr11-22222.raw
    $newname="cdrpccoeb".$1."-0".$2.".raw";
  }
  elsif($_[0]=~/.raw$/){
    $newname=$_[0];
  }
  return $newname;
}
