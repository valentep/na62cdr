#!/usr/bin/perl -w
# Author: Massimo Lamanna (Massimo.Lamanna@cern.ch) August 2000
#
# add new bkm in OnlineDataStop for new data 
#
# $Id: inspect_online.pl,v 1.9 2006/02/02 17:37:45 neyret Exp $

require 5.004;
use strict;
use diagnostics;
use POSIX;
use Sys::Hostname;

# my($CCF_ROOT)="/usr/local/compass/ccf";
my($CCF_ROOT) = "/online/detector/cdr";
if(-e "$ENV{HOME}/.ccfrc") {
    $CCF_ROOT = `cat "$ENV{HOME}/.ccfrc" 2>&1`;
    chomp($CCF_ROOT);
    $CCF_ROOT =~ s/CCF_ROOT//;
    $CCF_ROOT =~ s/ //g;
}
if(!-d $CCF_ROOT) {
#     $CCF_ROOT = "/usr/local/compass/ccf";
    $CCF_ROOT = "/online/detector/cdr";
}

require "$CCF_ROOT/toolkit/bkm_dir.pl";
# require "$CCF_ROOT/toolkit/objyenv.pl";
require "$CCF_ROOT/toolkit/ErrorReport.pl";
# require "$CCF_ROOT/toolkit/getDirMask1.pl";
require "$CCF_ROOT/toolkit/getDirMask1.pl";
require "$CCF_ROOT/toolkit/getFileSize.pl";
require "$CCF_ROOT/toolkit/miscenv.pl";


my($host) = getHost();

# my(@bkm_dir) = bkm_dir("-quiet","$CCF_ROOT/setup/setup.dat");
my(@bkm_entry) = ();
my(%bkm_entry) = ();
%bkm_entry = bkm_dir("-quiet","$CCF_ROOT/setup/setup.dat");

my($bkm_dir);
# my($data_dir) = "/shift/$host/data01/objsrvvy/cdr";
my($data_dir) = "/data/cdr";
# for  (@bkm_dir) {
#     /$host/ && ($bkm_dir = $_);
# }
foreach  (sort keys %bkm_entry) {
  if ( $host = $_) { $bkm_dir = $bkm_entry{$_}; }
}
die "$0: No bkm_dir on this host ($host). Check the setup.dat file..." unless defined($bkm_dir);

$bkm_dir = $bkm_dir;

my(%run) = getDirMask(
		      "$bkm_dir/OnlineDataStop",
		      "$data_dir"
		      );

my(%dataFileName) = getDataFileName($data_dir);


foreach (keys %run) {
  unless(  $run{$_}[1] eq "00" )
  {
    print("File $_ has 0 size $run{$_}[1].\n");
  } 
  if( $run{$_}[0] eq "01") {
      my $age = -M "$data_dir/$dataFileName{$_}[0]";
      if($run{$_}[0] eq "01" && (-z "$data_dir/$dataFileName{$_}[0]") && $age > 0.5 )
      {
	  print "Remove empty file: $data_dir/$dataFileName{$_}[0]\n";
	  system "ls -l $data_dir/$dataFileName{$_}[0]";
	  print("/bin/rm -f $data_dir/$dataFileName{$_}[0]\n");
#	    `rm $data_dir/$dataFileName{$_}[0]`;
      }
      elsif($run{$_}[0] eq "01" && $age > 0.2) {
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
      if((-z "$bkm_dir/OnlineDataStop/$dataFileName{$_}[0]") && $age > 0.3)
      {
	  print "Remove empty file: $bkm_dir/OnlineDataStop/$dataFileName{$_}[0]\n";
	  `/bin/rm $bkm_dir/OnlineDataStop/$dataFileName{$_}[0]`;
      }
      next;
  }
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


