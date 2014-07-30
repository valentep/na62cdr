#!/usr/bin/perl -w
# Author: Massimo Lamanna (Massimo.Lamanna@cern.ch) August 2000
#
# Tool to check the consistency of the directories on 
# the online machine
#
# $Id: inspect_online.pl,v 1.9 2006/02/02 17:37:45 neyret Exp $

require 5.004;
use strict;
use diagnostics;
use POSIX;
use Sys::Hostname;

sub main::get_ps();
sub main::ps_check;

# my($CCF_ROOT)="/usr/local/compass/ccf";
my($CCF_ROOT) = "/home/na62cdr/cdr";
if(-e "$ENV{HOME}/.ccfrc") {
    $CCF_ROOT = `cat "$ENV{HOME}/.ccfrc" 2>&1`;
    chomp($CCF_ROOT);
    $CCF_ROOT =~ s/CCF_ROOT//;
    $CCF_ROOT =~ s/ //g;
}
if(!-d $CCF_ROOT) {
#     $CCF_ROOT = "/usr/local/compass/ccf";
    $CCF_ROOT = "/home/na62cdr/cdr";
}

require "$CCF_ROOT/toolkit/bkm_dir.pl";
require "$CCF_ROOT/toolkit/ErrorReport.pl";
require "$CCF_ROOT/toolkit/getDirMask1.pl";
require "$CCF_ROOT/toolkit/getFileSize.pl";
require "$CCF_ROOT/toolkit/miscenv.pl";
require "$CCF_ROOT/toolkit/decode_fdb.pl";

# my $castor_dir = "/castor/cern.ch/compass/merger/2006/raw/test";
# my $castor_dir = "/castor/cern.ch/compass/merger/2007/raw/tmp";
my($castor_dir) = getRAWrepository2("-quiet","$CCF_ROOT/setup/setup.dat");

my($host) = getHost();

# my(@bkm_dir) = bkm_dir("-quiet","$CCF_ROOT/setup/setup.dat");
my(@bkm_entry) = ();
my(%bkm_entry) = ();
%bkm_entry = bkm_dir("-quiet","$CCF_ROOT/setup/setup.dat");

my($bkm_dir);
# my($data_dir) = "/shift/$host/data01/objsrvvy/cdr";
my($data_dir) = "/merger/cdr";
# for  (@bkm_dir) {
#     /$host/ && ($bkm_dir = $_);
# }

foreach  (sort keys %bkm_entry) {
  if ( $host eq $_) { $bkm_dir = $bkm_entry{$_}; }
}
die "$0: No bkm_dir on this host ($host). Check the setup.dat file..." unless defined($bkm_dir);

$bkm_dir = $bkm_dir;


my(%run) = getDirMask(
		      "$bkm_dir/OnlineDataStop",
		      "$bkm_dir/OnlineDataComplete",
		      "$bkm_dir/OnlineTransferStart",
		      "$bkm_dir/OnlineTransferStop",
		      "$bkm_dir/OnlineTransferComplete",
		      "$bkm_dir/OnlineDataClear",
		      "$data_dir"
		      );


my(%fileSize) = getFileSize(
			    "$bkm_dir/OnlineDataStop",
			    "$bkm_dir/OnlineDataComplete",
			    "$bkm_dir/OnlineTransferStart",
			    "$bkm_dir/OnlineTransferStop",
			    "$bkm_dir/OnlineTransferComplete",
			    "$bkm_dir/OnlineDataClear",
			    "$data_dir"
			    );


my(%dataFileName) = getDataFileName($data_dir);

my $ntot = 0;
my $ndsk = 0;
my $ncle = 0;
my $nnbk = 0;
my $nntp = 0;

my $totSz = 0;
my $dskSz = 0;
my $cleSz = 0;
my $nbkSz = 0;
my $ntpSz = 0;

my $dfcmd2 = 'df -m $data_dir | grep /merger | awk "{print \$2;}"';
my $dfcmd3 = 'df -m $data_dir | grep /merger | awk "{print \$3;}"';
my $dfcmd4 = 'df -m $data_dir | grep /merger | awk "{print \$4;}"';

if($host eq "pccoeb20") {
$dfcmd2 = 'df -m $data_dir | grep /merger | awk "{print \$1;}"';
$dfcmd3 = 'df -m $data_dir | grep /merger | awk "{print \$2;}"';
$dfcmd4 = 'df -m $data_dir | grep /merger | awk "{print \$3;}"';
}


my $freeDsk = strtol(`$dfcmd4`,10);
my $usedDsk = strtol(`$dfcmd3`,10);
my $totalDsk = strtol(`$dfcmd2`,10);

print("\nFull statistic:\n\n");
my $ttt = 0;
foreach (keys %run) {
  my $fSize = $fileSize{$_}[0];
  $totSz += $fSize;
    $ntot++;
#  print("File $_  0: $run{$_}[0]  1: $run{$_}[1]\n");
  unless(  $run{$_}[1] eq "0000000" )
  {
    # print("File $_ has 0 size $run{$_}[1] ($run{$_}[0])\n");
  } 
    if( $run{$_}[0] eq "1111101" ) {
	$ndsk++;
	$dskSz += $fSize;
	next; # Still on disk
    }
    if( $run{$_}[0] eq "1111110" ) {
	$ncle++;
	$cleSz += $fSize;
	next; # Removed
    }

#my $age = -M "$data_dir/$dataFileName{$_}[0]";
my $age = -M "$data_dir/$_";

  if( $run{$_}[0] eq "1110001" ) {
      my $age = -M "$bkm_dir/OnlineTransferStart/$_";
      if($age > 1.0 && system("rm $bkm_dir/OnlineTransferStart/$_") == 0) {
	  $run{$_}[0] = "1100001";
	  print("rm $bkm_dir/OnlineTransferStart/$_  Age = $age days.\n");
      }
  }
  if( $run{$_}[0] eq "1111001" ) {
      $nntp++;
      $ntpSz += $fSize;
      # Copied to disk pool but still not on tape
  }
  if( $run{$_}[0] eq "1101001" ) {
      if(system("cp $bkm_dir/OnlineDataComplete/$_ $bkm_dir/OnlineTransferStart") == 0) {
	  print("$_: bookmark in OnlineTransferStart missing (data not yet on tape), copied it from OnlineDataComplete\n");
      }
      next;
  }
  if( $run{$_}[0] eq "1101101" ) {
      if(system("cp $bkm_dir/OnlineDataComplete/$_ $bkm_dir/OnlineTransferStart") == 0) {
	  print("$_: bookmark in OnlineTransferStart missing (data already on tape), copied it from OnlineDataComplete\n");
      }
      next;
  }
  if( $run{$_}[0] eq "1101110" ) {
      if(system("cp $bkm_dir/OnlineDataComplete/$_ $bkm_dir/OnlineTransferStart") == 0) {
	  print("$_: bookmark in OnlineTransferStart missing (data already on tape and deleted), copied it from OnlineDataComplete\n");
      }
      next;
  }
  if( $run{$_}[0] eq "1000000" ) {
      $age = -M "$bkm_dir/OnlineDataStop/$_";
      if((-e "$bkm_dir/OnlineDataStop/$_") && $age > 0.1)
      {
	  print "Remove alone bookmark file: $bkm_dir/OnlineDataStop/$_\n";
	  `/bin/rm $bkm_dir/OnlineDataStop/$_`;
      }
      next;
  }
  if( $run{$_}[0] eq "1000001" ||  $run{$_}[0] eq "0000001" ) {
      my $age = -M "$data_dir/$dataFileName{$_}[0]";
      if($run{$_}[0] eq "0000001" && (-z "$data_dir/$dataFileName{$_}[0]") && $age > 0.004 )
      {
	  print "Remove empty file: $data_dir/$dataFileName{$_}[0]\n";
	  system "ls -l $data_dir/$dataFileName{$_}[0]";
	  print("rm $data_dir/$dataFileName{$_}[0]\n");
          `/bin/rm -f $data_dir/$dataFileName{$_}[0]`;
      }
      elsif($run{$_}[0] eq "0000001" && $age > 0.005) {
	  open(ONL_STOP, ">$bkm_dir/OnlineDataStop/$dataFileName{$_}[0]");
	  my $d = `date +\"%d %b %Y %H:%M:%S\"`;
	  my @st = stat("$data_dir/$dataFileName{$_}[0]");
	  my $s = $st[7]/1024;
	  $s =~ m/(\d+)\.(\d+)/;
	  $s = $1;
	  print ONL_STOP "$data_dir/$dataFileName{$_}[0] size = $s kB, time = $d";
	  close ONL_STOP;
      }
      $age = -M "$bkm_dir/OnlineDataStop/$dataFileName{$_}[0]";
      if((-z "$bkm_dir/OnlineDataStop/$dataFileName{$_}[0]") && $age > 0.1)
      {
	  print "Remove empty file: $bkm_dir/OnlineDataStop/$dataFileName{$_}[0]\n";
	  `/bin/rm $bkm_dir/OnlineDataStop/$dataFileName{$_}[0]`;
      }
      $nnbk++;
      $nbkSz += $fSize;
      printf("- %-30s   %07d   Size: %8.3f Mb\n", $dataFileName{$_}[0], $run{$_}[0], $fSize/1024/1024);
      $ttt = 1;
      next;
  }
  if($run{$_}[0] eq "1111001" && -M "$bkm_dir/OnlineTransferStop/$dataFileName{$_}[0]" > 1) {
      # if file is not completed since 1 day, then check castor file size:
      my $castor_fn = $dataFileName{$_}[0];
      $castor_fn =~ s/\.dat/\.raw/;
      $castor_fn = "$castor_dir/$castor_fn";
      my $castor_stat = `/usr/bin/nsls -l $castor_fn`;
      if(defined($castor_stat) && ($castor_stat =~ /\S+\s+\d\s+\w+\s+\w+\s+(\d+)\s+/)) {
	  my $castor_size = $1;
	  my $disk_stat = `ls -l $data_dir/$dataFileName{$_}[0]`;
	  if(defined($disk_stat) && ($disk_stat =~ /\S+\s+\d\s+\w+\s+\w+\s+(\d+)\s+/)) {
	      my $disk_size = $1;
	      if($disk_size != $castor_size) { # remove BKM (start && stop) files if a problem with castor file size
		  print("Castor file size and disk file size are differ! Remove BKM files.\n");
		  print("rm $bkm_dir/OnlineTransferStop/$dataFileName{$_}[0] $bkm_dir/OnlineTransferStart/$dataFileName{$_}[0]\n");
	      }
	  }
	  else {
	      print("Cannot find CDR file: $data_dir/$dataFileName{$_}[0]\n");
	  }
      }
      else {
#	  print("File $castor_fn has not been found. Remove BKM files.\n");
	  system("rm $bkm_dir/OnlineTransferStop/$dataFileName{$_}[0] $bkm_dir/OnlineTransferStart/$dataFileName{$_}[0]");
      }
  }
  $ttt = 1;
  printf("- %-30s   %07d   Size: %8.3f Mb\n", $_ , $run{$_}[0], $fSize/1024/1024);
}
if($ttt)
{
  print "                                   |||||||- $data_dir/\n";
  print "                                   ||||||-- $bkm_dir/OnlineDataClear/\n";
  print "                                   |||||--- $bkm_dir/OnlineTransferComplete/\n";
  print "                                   ||||---- $bkm_dir/OnlineTransferStop/\n";
  print "                                   |||----- $bkm_dir/OnlineTransferStart/\n";
  print "                                   ||------ $bkm_dir/OnlineDataComplete/\n";
  print "                                   |------- $bkm_dir/OnlineDataStop/\n";
}
print "\nCASTOR directory: $castor_dir/\n";
# print "\BKM directory: $bkm_dir/\n";
print "\n\nNtot files                                            = $ntot\n";
print "Ntot files treated and ready to be removed            = $ndsk\n";
print "Ntot files already removed from the online disk pool  = $ncle\n";
print "Ntot not bookmarked files                             = $nnbk\n";
my $rel = $ntot - $ndsk - $ncle;
print "Ntot files not transfered yet                         = $rel\n";
my $relSz = $totSz - $dskSz - $cleSz;
my $ncsSz = $relSz - $ntpSz;
my $gigobyte = 1024*1024*1024;
my $freespace = 100*$usedDsk/(1.*$totalDsk);
my $freespaceGB = $freeDsk/1024.;
printf("\n\nTotal file size                                       = %8.3f GB\n",$totSz/$gigobyte);
printf("Total disk %% used in /merger filesystem                 =   %3.1f%%\n", $freespace);
printf("Total free disk space in /merger filesystem             = %8.3f GB\n", $freespaceGB);
printf("Total file size treated and ready to be removed       = %8.3f GB\n",$dskSz/$gigobyte);
printf("Total file size not yet copied to Castor disk pool    = %8.3f GB\n",$ncsSz/$gigobyte);
printf("Total file size not finished yet                      = %8.3f GB\n",$relSz/$gigobyte);
# printf("Total file size removed from the pool                 = %8.3f Gb\n",$cleSz/$gigobyte);
my $dirSz = getDirSize($data_dir);
printf("Size of $data_dir           = %8.3f GB\n", $dirSz/$gigobyte);
printf("\t\t1 GB = %d bytes\n", $gigobyte);



my %controlhash=qw();

push @{$controlhash{1}},"onl_cdr/interface_online.pl",1;
push @{$controlhash{2}},"onl_cdr/submitStage0.pl",1;
push @{$controlhash{3}},"onl_cdr/complete_online.pl",1; 
push @{$controlhash{4}},"onl_cdr/cleanup_online.pl",1;

my %ps_exist=qw();
my @psoutput=();
my $user="objsrvvy";
get_ps();

foreach my $id (sort keys %controlhash) {
    ps_check($id,0);
}


$host = getHost();
# my $newdate = `date +\"%d %b %Y %H:%M:%S\"`;
my $newdate = `date +\"%s\"`;
chomp($newdate);
my $savevalsf="/online/detector/cdr/reports/cdr_vals_$host.tcl";
`/bin/rm -f $savevalsf`;
open(SAVE_VALS, ">$savevalsf");
print SAVE_VALS "set sdate($host) $newdate\n";
print SAVE_VALS "set ntot($host) $ntot\n";
print SAVE_VALS "set ndsk($host) $ndsk\n";
print SAVE_VALS "set ncle($host) $ncle\n";
print SAVE_VALS "set nnbk($host) $nnbk\n";
print SAVE_VALS "set totSz($host) $totSz\n";
print SAVE_VALS "set dskSz($host) $dskSz\n";
print SAVE_VALS "set cleSz($host) $cleSz\n";
print SAVE_VALS "set ncsSz($host) $ncsSz\n";
print SAVE_VALS "set dirSz($host) $dirSz\n";
print SAVE_VALS "set freeDsk($host) $freeDsk\n";
print SAVE_VALS "set usedDsk($host) $usedDsk\n";
print SAVE_VALS "set totalDsk($host) $totalDsk\n";

my $psex="";
foreach (sort keys %ps_exist){
# print "_ $_ exist  $ps_exist{$_} \n";
  if ( $ps_exist{$_} == 1 ) {
    $psex = "${psex}Y";
  } else {
    $psex = "${psex}N";
  }
}
print SAVE_VALS "set psexist($host) $psex\n";
close SAVE_VALS;


if ( $freespaceGB < 220 ) {
  my $gsmstr = "inspect_online.pl: Warning free space on /merger is getting low ! free disk space $freespaceGB GB, percentage $freespace";
  gsm_alarm($gsmstr);
}

if ( $rel > 600 ) {
  my $gsmstr = "inspect_online.pl: Lot of raw data files ($rel) not transfered, looks like migration is stuck...";
  gsm_alarm($gsmstr);
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



sub ps_check  {
    my $count=0; my $swapped=0;
    my $rec=$_[1];

    return if($rec>5);  # avoid unlimited recursive calls

    my $commandline=$controlhash{$_[0]}[0];
    my $short=$controlhash{$_[0]}[0];
    $short=~ s/^\w+\///; 
    $short=~s/^([\w\d]+.pl)\s*[\w\s\/\.]*/$1/;
    my $swap=$controlhash{$_[0]}[0];
    $swap=~ s/^\w+\///;
    $swap=~ s/\.pl\s*[\w\s\/\.]*//;
    $swap=~ s/(\w{0,6})\w*/$1/;

    foreach (@psoutput){
	if(/$commandline/){ # check for full command line
	    $count++;
	}
    }

    if($count==0){ # check again for truncated command line (swapped !)
	foreach (@psoutput){
	    if(/\[$swap/){ 
		$swapped++;
		last;
	    }
	}
	if($swapped>0){
	    system "/usr/bin/killall -USR1 $short";
	    sleep(2);
	    get_ps();	    
	    ps_check($_[0],$rec+1);   # recursive ..
	    return 1;
	}
    }

    if ($count==$controlhash{$_[0]}[1]) {
      $ps_exist{$_[0]}=1;
    } else {
      $ps_exist{$_[0]}=0;
    }
}


sub get_ps(){
    system "date"; # for the log
    @psoutput=();
    @psoutput=`ps -u $user -o command --columns 255 `;
}
