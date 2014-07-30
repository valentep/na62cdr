#!/usr/bin/perl -w
# 

require 5.004;
use strict;
use diagnostics;
use Time::Local;
use Sys::Hostname;   # Uli

sub gsm_alarm;

# my $ccf_dir = "/usr/local/compass/ccf/onl_cdr";
my $ccf_dir = "/home/na62cdr/cdr";
my @core_files = `ls -1 $ccf_dir/core.* 2> /dev/null`;

if($#core_files >= 0) {
    gsm_alarm("core files on the event builders.\n");
    if($#core_files > 100) {
	gsm_alarm("Too many core files on the event builders.\n");
    }
}


sub gsm_alarm {

    my @arg = @_;

    if(-e "$ccf_dir/sms_address.enable") {
#        my $to_address = "vladimir.frolov\@163466.gsm.cern.ch";
	my $to_address = `cat $ccf_dir/sms_address.enable`;
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
