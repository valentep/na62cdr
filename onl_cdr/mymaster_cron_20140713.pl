#!/usr/bin/perl -w
# Author: Uli '02
# New Design with kill -USR1 
# $Id: mymaster_cron.pl,v 1.1 2006/02/02 17:37:45 neyret Exp $

require 5.004;
use strict;
use diagnostics;

use Sys::Hostname;

sub main::get_ps();
sub main::ps_check;
sub main::kill_daemons();
sub main::start_daemons();

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

require "$CCF_ROOT/toolkit/ErrorReport.pl";
require "$CCF_ROOT/toolkit/miscenv.pl";

my($hostcdr) = getHost();

my $mode="-verbose";
$#ARGV == 0 && ($mode=$ARGV[0]);
die "Unknown option $mode" unless ($mode eq "-verbose" 
				   || $mode eq "-quiet");


my %controlhash=qw();
my @to_gsm=();

################################################################################
# Fill in user name and logdir

my $user="na62cdr";
my $logdir = "/merger/logs"; # default value, can be changed below ..

################################################################################
# Fill in program information here
# ID as hash key, Commandline, No. of instances

#push @{$controlhash{1}},"onl_cdr/interface_online.pl",1;
push @{$controlhash{2}},"onl_cdr/submitStage0.pl",1;
push @{$controlhash{3}},"onl_cdr/complete_online.pl",1; 
push @{$controlhash{4}},"onl_cdr/cleanup_online.pl",1;

################################################################################
################################################################################


# check that the log directory is there

foreach (keys %controlhash) {
    my $dir=$controlhash{$_}[0];
    $dir =~ s/\s//g;
    $dir =~ s/\/.*//g;
    if(!-e "$logdir/$dir") { #permissions not checked...yet
	print "$logdir/$dir did not exist ..\n";
	mkdir ("$logdir/$dir",07777)
    }
}

my %to_start=qw();
my %to_stop=qw();

my @psoutput=();
get_ps();

foreach my $id (sort keys %controlhash){
    ps_check($id,0);
}

kill_daemons();
sleep 2 if((scalar keys %to_stop)>0);
start_daemons();

if($mode eq "-verbose"){
    gsm_alarm(@to_gsm);
}else{
    print "GSM: @to_gsm \n" unless $#to_gsm<0;
}


###############################################################################

sub kill_daemons(){
    foreach (keys %to_stop){
	my $short=$controlhash{$_}[0];
	$short=~ s/^\w+\///; 
	$short=~s/^([\w\d]+.pl)\s*[\w\s\/\.]*/$1/;
	next if $short =~ /submitS/;
	print "/usr/bin/killall $short\n";
	unless(system("/usr/bin/killall -9 $short") ==0){
	    # killall failed
	    get_ps2();
	    foreach (@psoutput){
		if(/^\s*(\d+)[\s\d\w\/\-\:\?]+$short/){
		    print "kill -9 $1\n";
		    system "kill -9 $1";
		}
	    }
	}
	push @to_gsm,"kill $_ // ";
    }
}


sub start_daemons(){
    foreach (keys %to_start){
	my $log="$logdir/$controlhash{$_}[0]";
	$log=~ s/\s[\w\/\.]+//g; # cut away options to program
	$log =~ s/\.pl/\.log/;
	my $lock="$CCF_ROOT/$controlhash{$_}[0]";
        $lock=~ s/\.pl/\.$hostcdr\.lock/;
	$lock =~ s/onl_cdr/lockfiles/;
	print "lock: $lock \n";
	if(-e $lock){
	    my $diff=time() - (stat($lock))[10];
	    push @to_gsm, "LOCK for $_ //" if($diff>7200);
	    next;
	}
	system "touch $log" unless(-e $log);
	print "$CCF_ROOT/$controlhash{$_}[0] >> $log 2>&1 &\n";
	system "$CCF_ROOT/$controlhash{$_}[0] >> $log 2>&1 &\n";
	sleep(2);
	push @to_gsm,"start $_ // ";
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

    unless($count==$controlhash{$_[0]}[1]){
	if($count==0){
	    $to_start{$_[0]}=1;
	    print "--$controlhash{$_[0]}[0]-- missing ! Started ..\n";
	}else{
	    $to_stop{$_[0]}=1;
	    $to_start{$_[0]}=1;
	    print "Wrong number of --$controlhash{$_[0]}[0]-- running ! Killed ..\n";
	}
    }
}


sub get_ps(){
    system "date"; # for the log
    @psoutput=();
    @psoutput=`ps -u $user -o command --columns 255 `;
}
sub get_ps2(){
    system "date"; # for the log
    @psoutput=();
    @psoutput=`ps -u $user -o pid,command --columns 255 `;
}   

sub gsm_alarm {
    my @arg = @_;
    my %arg=qw();

    foreach (@arg){ $arg{$_}=1};
    @arg=keys(%arg);

    exit if ($#arg<0); # nothing to send
    if(-e "$CCF_ROOT/sms_address.enable" && $mode eq "-verbose") {
	my $to_address = `cat $CCF_ROOT/sms_address.enable`;
	chomp($to_address);
	my $subject = $hostcdr.": @arg";
	open MAIL,"| /usr/sbin/sendmail -t -oi";
	print MAIL "From: $hostcdr <objsrvvy\@mail.cern.ch>\n";
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

