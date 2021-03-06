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

my($CCF_ROOT) = `grep CCF_ROOT /merger/etc/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'`;
defined $CCF_ROOT || die "Home directory CCF_ROOT not found in configuration file /merger/etc/.ccfrc";
chomp($CCF_ROOT);
print "===============================================================\n";
print "===============================================================\n";
print "CCF_ROOT      ",$CCF_ROOT,"\n";

require "$CCF_ROOT/toolkit/ErrorReport.pl";
require "$CCF_ROOT/toolkit/miscenv_mod.pl";
require "$CCF_ROOT/toolkit/decode_fdb_mod.pl";

my $mode="-verbose";
$#ARGV == 0 && ($mode=$ARGV[0]);
die "Unknown option $mode" unless ($mode eq "-verbose" || $mode eq "-quiet");

my %controlhash=qw();
my %wrapperhash=qw();
my @to_m=();

my($setupfile) = "$CCF_ROOT/setup/setup.dat";
my($usersfile) = "$CCF_ROOT/setup/users.dat";

# Fill in user name and logdir
my($hostcdr) = getHost();
my($user) = getUser_mod($usersfile);
my($logdir) = getLogsDir("-quiet",$setupfile);

################################################################################
# Fill in program information here
# ID as hash key, Commandline, No. of instances

#push @{$controlhash{1}},"onl_cdr/interface_online.pl",1;
push @{$controlhash{1}},"perl -w $CCF_ROOT/onl_cdr/submitStage0.pl",1;
push @{$wrapperhash{1}},"onl_cdr/launch_submitStage0.sh",1;
###push @{$controlhash{3}},"onl_cdr/complete_online.pl",1; 
###push @{$controlhash{4}},"onl_cdr/cleanup_online.pl",1;

################################################################################
################################################################################


# check that the log directory is there

foreach (keys %wrapperhash) {
    my $dir=$wrapperhash{$_}[0];
    $dir =~ s/\s//g;
    $dir =~ s/\/.*//g;
    if(!-e "$logdir/$dir") { #permissions not checked...yet
        die "$logdir/$dir did not exist ..\n";
#	mkdir ("$logdir/$dir",07777)
    }
}

my %to_start=qw();
my %to_stop=qw();

my @psoutput=();
get_ps();

foreach my $id (sort keys %controlhash){
    print "ps_check: $id\n";
    ps_check($id,0);
}

kill_daemons();
sleep 2 if((scalar keys %to_stop)>0);
start_daemons();

if($mode eq "-verbose"){
    m_alarm(@to_m);
}else{
    print "Message: @to_m \n" unless $#to_m<0;
}


###############################################################################

sub kill_daemons(){
    foreach (keys %to_stop){
	my $short=$controlhash{$_}[0];
	$short=~ s/^\w+\///; 
	$short=~s/^([\w\d]+.pl)\s*[\w\s\/\.]*/$1/;
#	next if $short =~ /submitS/;
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
	push @to_m,"kill $short // ";
    }
}


sub start_daemons(){
    foreach (keys %to_start){
	my $log="$logdir/$wrapperhash{$_}[0]";
	$log=~ s/\s[\w\/\.]+//g; # cut away options to program
	$log =~ s/\.pl/\.log/;
	my $lock="$CCF_ROOT/$wrapperhash{$_}[0]";
        $lock=~ s/\.pl/\.$hostcdr\.lock/;
	$lock =~ s/onl_cdr/lockfiles/;
	print "lock: $lock \n";
	if(-e $lock){
	    my $diff=time() - (stat($lock))[10];
	    push @to_m, "LOCK for $lock //" if($diff>7200);
	    next;
	}
	system "touch $log" unless(-e $log);
	print "$CCF_ROOT/$wrapperhash{$_}[0]\n";
	system "$CCF_ROOT/$wrapperhash{$_}[0]\n";
	sleep(2);
	push @to_m,"start $wrapperhash{$_}[0] // ";
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

    print "$short\n";

    foreach (@psoutput){
	if(/$commandline/){ # check for full command line
	    $count++;
	    print "$_, count++ ($count)\n";
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
#	    system "/usr/bin/killall -USR1 $short";
	    print "/usr/bin/killall -USR1 $short\n";
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

sub m_alarm {
    my @arg = @_;
    my %arg=qw();

    foreach (@arg){ $arg{$_}=$_};
    @arg=keys(%arg);

    exit if ($#arg<0); # nothing to send
    if(-e "$CCF_ROOT/email.enable" && $mode eq "-verbose") {
	my $to_address = `cat $CCF_ROOT/email.enable`;
	chomp($to_address);
	my $subject = $hostcdr.": @arg";
	open MAIL,"| /usr/sbin/sendmail -t -oi";
	print MAIL "From: $hostcdr <na62.cdr\@cern.ch>\n";
	print MAIL "To: $to_address \n";
	print MAIL "Subject: $subject \n";
	print MAIL "\n";
	print MAIL "No message body to be sent along\n";
	close MAIL;
	print "m_alarm: sent: $subject\n";
    }
    else {
	print "m_alarm: disabled\n";
    }
}

