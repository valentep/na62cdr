#!/usr/bin/perl -w
# Author: Ulrich Fuchs
# $Id: tmpmon.pl,v 1.4 2004/05/20 16:13:47 neyret Exp $

require 5.004;
use strict;
use diagnostics;

#my($CCF_ROOT)="/usr/local/compass/ccf";
my($CCF_ROOT)="/home/na62cdr/cdr";
if(-e "$ENV{HOME}/.ccfrc") {
    $CCF_ROOT = `cat "$ENV{HOME}/.ccfrc" 2>&1`;
    chomp($CCF_ROOT);
    $CCF_ROOT =~ s/CCF_ROOT//;
    $CCF_ROOT =~ s/ //g;
}
if(!-d $CCF_ROOT) {
    $CCF_ROOT = "/home/na62cdr/cdr";
}

# use Mail::Mailer;
use Sys::Hostname;

# my $to_address = "vladimir.frolov\@cern.ch, massimo.lamanna\@cern.ch, ulrich.fuchs\@cern.ch, damien.neyret\@cern.ch";
my $to_address = "felice.pantaleo\@cern.ch";
if(-e "$CCF_ROOT/sms_address.enable") {
  my $sms_address=`cat $CCF_ROOT/sms_address.enable`;
} else {
  my $sms_address='';           
}

my @df;
my $dfp;
my $dfb;

my $host=`/bin/hostname -s`;
chomp($host);

my @disk = (
	    "/merger"
	    );

for (@disk) {
    
    @df=`df $_`;
    $dfp=(split(/\s+/,$df[1]))[4];
    $dfb=(split(/\s+/,$df[1]))[3];
    $dfp=~s/\%//;

    if($dfb<10000000){
	open MAIL,"| /usr/sbin/sendmail -t -oi";
	print MAIL "From: na62cdr\@na62merger.cern.ch\n";
	print MAIL "To: $to_address\n";
	print MAIL "Subject: $_ full !! \n\n";
	close MAIL;
    }
}

@df=`df /tmp`;
$dfp=(split(/\s+/,$df[1]))[4];
$dfb=(split(/\s+/,$df[1]))[3];
$dfp=~s/\%//;

if($dfp>85 || $dfb<500000){
#    my $ret_val = system("/usr/local/compass/ccf/onl_cdr/backup_logs.pl");
    my $ret_val = system("/home/na62cdr/cdr/onl_cdr/backup_logs.pl");
    if($ret_val != 0) {
	open MAIL,"| /usr/sbin/sendmail -t -oi";
	print MAIL "From: na62cdr\@na62merger.cern.ch\n";
	print MAIL "To: $to_address \n";
	print MAIL "Subject: /tmp full !! \n\n";
	
	print MAIL "Host: ".hostname()."\n\n";
	
	foreach (@df){ print MAIL "$_" }

	close MAIL;
    }
}
