#!/usr/bin/perl -w
#


require 5.004;
use strict;
use diagnostics;

#my($CCF_ROOT) = "/usr/local/compass/ccf";
my($CCF_ROOT) = "/home/na62cdr/cdr";
defined $CCF_ROOT || die "Define CCF_ROOT enviroment variable";
chomp($CCF_ROOT);

require "$CCF_ROOT/toolkit/miscenv.pl";


print("\n\n\t\t*********\n");
system("date");
print("\n");


my($hostcdr) = getHost();

my $cdr_dir = "/merger/cdr";

my @file_list = `ls -1 $cdr_dir`;

foreach my $fn (@file_list) {
    chomp($fn);
#     if(defined ($fn) && ($fn =~ /cdr\d\d-\d\d\d\d\d_\d\d\d\b/) && !($fn =~ /cdr\d\d-\d\d\d\d\d_\d\d\d\.raw/)) {
#    if(defined ($fn) && ($fn =~ /cdrna62merger\d\d-\d\d\d\d\d\.\d\d\d\b/) && !($fn =~ /cdrna62merger\d\d-\d\d\d\d\d\.\d\d\d\.raw/)) {
    if(defined ($fn) && ($fn =~ /cdrna62merger\d{2}-\d{3,6}\.\d{3}\b/) && !($fn =~ /cdrna62merger\d{2}-\d{3,6}\.\d{3}\.raw/)) {
	print("$fn\n");
	my $full_fn = "$cdr_dir/$fn";
	if( (-s $full_fn) && (-M $full_fn) > 0.05) { # file exists, older then 1 hour and its size != 0
	    my $ret_val = system("mv $full_fn ${full_fn}.raw");
	    if($ret_val != 0) {
		print("Cannot rename file $full_fn\n");
	    }
	}
	elsif( -z "$full_fn" && (-M $full_fn) > 0.05) {
	    print("$fn   is empty\n");
	    my $ret_val = system("rm $full_fn");
	    if($ret_val != 0) {
		print("Cannot remove file: $full_fn\n");
	    }
	}
	else {
	    print("File: $full_fn still on the disk.\n");
	}
    }
#    if(defined ($fn) && ($fn =~ /cdrna62merger\d\d-\d\d\d\d\d-t[0-9a-f]{8}\.\d\d\d\b/) && !($fn =~ /cdrna62merger\d\d-\d\d\d\d\d-t[0-9a-f]{8}\.\d\d\d\.raw/)) {
    if(defined ($fn) && ($fn =~ /cdrna62merger\d{2}-\d{3,6}-t[0-9a-f]{8}\.\d{3}\b/) && !($fn =~ /cdrna62merger\d{2}-\d{3,6}-t[0-9a-f]{8}\.\d{3}\.raw/)) {
	print("$fn\n");
	my $full_fn = "$cdr_dir/$fn";
	if( (-s $full_fn) && (-M $full_fn) > 0.05) { # file exists, older then 1 hour and its size != 0
# 	    print("mv $full_fn ${full_fn}.raw\n");
	    my $ret_val = system("mv $full_fn ${full_fn}.raw");
	    if($ret_val != 0) {
		print("Cannot rename file $full_fn\n");
	    }
	}
	elsif( -z "$full_fn" && (-M $full_fn) > 0.05) {
	    print("$fn   is empty\n");
#	    print("rm $full_fn\n");
	    my $ret_val = system("rm $full_fn");
	    if($ret_val != 0) {
		print("Cannot remove file: $full_fn\n");
	    }
	}
	else {
	    print("File: $full_fn still on the disk.\n");
	}
    }
}
