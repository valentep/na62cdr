#!/usr/bin/perl -w
# 

require 5.004;
use strict;
use diagnostics;
use Time::Local;
use Sys::Hostname;   # Uli
#####
use File::Basename;
use DBI;


my($CCF_ROOT) = `grep CCF_ROOT $ENV{HOME}/.ccfrc | sed 's/CCF_ROOT//' | sed 's/ //g'`;
defined $CCF_ROOT || die "Home directory CCF_ROOT not found in configuration file $ENV{HOME}/.ccfrc";
chomp($CCF_ROOT);
print "===============================================================\n";
print "===============================================================\n";
print "CCF_ROOT      ",$CCF_ROOT,"\n";

require "$CCF_ROOT/toolkit/decode_fdb_mod.pl";
require "$CCF_ROOT/toolkit/miscenv_mod.pl";
require "$CCF_ROOT/toolkit/getDirMask_mod.pl";
require "$CCF_ROOT/toolkit/ls_stat_full.pl";
require "$CCF_ROOT/toolkit/bkm_dir.pl";

require "dbutils.pl";
sub insert_file_entry;

my($setupdbfile) = "$CCF_ROOT/setup/setupdb.dat";
my($setupfile) = "$CCF_ROOT/setup/setup.dat";
my($usersfile) = "$CCF_ROOT/setup/users.dat";
#######################################################
my($user) = getUser_mod($usersfile);
my $thishost=getHost();
print "$0: starting... ".`date`;
print "===============================================================\n";
print "Host:         $thishost\n";
print "User:         $user\n";
print "===============================================================\n";
print "Parsing setup file: $setupfile\n";
my($datayear) = getDataYear("-quiet",$setupfile);
my($datadir) = getDataDir("-quiet",$setupfile);
print "Processing year:    $datayear\n";
print "datadir:            $datadir\n";

my($bkm_dir);
my(@bkm_entry) = ();
my(%bkm_entry) = ();
%bkm_entry = bkm_dir("-quiet",$setupfile);

foreach  (sort keys %bkm_entry) {
  if ( $thishost = $_) { $bkm_dir = $bkm_entry{$_}; }
}
die "$0: No bkm_dir on this host ($thishost). Check the setup.dat file..." unless defined($bkm_dir);

my($bkmrootdir) = $bkm_dir;
my($bkmstartdir)    = "$bkmrootdir/OnlineTransferStart";
my($bkmstopdir)     = "$bkmrootdir/OnlineTransferStop";
my($bkmcompletedir) = "$bkmrootdir/OnlineTransferComplete";
my($bkmdatadonedir) = "$bkmrootdir/OnlineDataComplete";

print "bkmstartdir:          $bkmstartdir\n";
print "bkmstopdir:           $bkmstopdir\n";
print "bkmcompletedir:       $bkmcompletedir\n";
print "bkmdatadonedir:       $bkmdatadonedir\n";

print "===============================================================\n";
print "Parsing setup DB file: $setupdbfile\n";
my $myhost=getDBhost("-quiet",$setupdbfile);
my $myport=getDBport("-quiet",$setupdbfile);
my $dbuser = getDBuser("-quiet",$setupdbfile);
my $pw = getDBpw("-quiet",$setupdbfile);

my $host = $myhost.":".$myport;
my $db = "na62_bk";
my $datab = "DBI:mysql:".$db;
my $thedb = $datab."\;host=".$host;
print "===============================================================\n";
print "Connecting to $thedb... \n";
my $connect = DBI->connect($thedb, $dbuser, $pw) or die "Connection Error: $DBI::errstr\n";

my(%the_list) = getDirMask_mod("$bkmdatadonedir","$datadir");

print "===============================================================\n";
foreach (keys %the_list) {
    my $flag=$the_list{$_}[0]; 
    print "DEBUG:: $flag ::\n";
    if($flag eq "11" || $flag eq "01" ) { 
	my $f=$_;
	my $thisisthefile = "$datadir/$f";	
	my @disk_stat = ls_stat_full($thisisthefile);
	my $filesize=$disk_stat[1];
	my $filecrea=timelocal_to_dbtime($disk_stat[2]);
	my $timestamp="3000-01-01 00:00:00";
	my $fsize=$filesize;
	print "Processing file: $thisisthefile\n";
	if($flag eq "11") { 
	    my $source="$bkmdatadonedir/$f";	
	    if(!(-e $source)) {
		die "$0: Propagate error: $source";
	    }
	    open (IN,$source) || die "$0: cannot open $source for reading: $!";
	    my @lines =  <IN>;
	    if(!defined($lines[0]) || !defined($lines[1]) || !defined($lines[2])) {
		print "Invalid $source file!\n\n";
	    }else{
		$lines[2] =~ /datetime\:+\s+([\d]+)\-([\d]+)\-([\d]+)\_([\d]+):([\d]+)\:([\d]+)/;
		my $yy=$3+2000;
		$timestamp="$yy-$2-$1 $4:$5:$6";
		$lines[1] =~ /size\:+\s+([\d]+)/;
		my $fsize = $1;
		if($fsize != $filesize){
		    print "Warning: Different file size ($fsize) in $source!\n\n";
		} 
		my $fname=$lines[0];
		chomp $fname;
		if(!($fname eq $thisisthefile)){
		    print "Different file name ($fname) in $source!\n\n";
		} 
	    } 
	} 
	insert_file_entry($connect,$thisisthefile,$timestamp,$filecrea,$fsize);
    }
}



######################################################################

sub insert_file_entry(){
    my $conn=$_[0];
    my $currentfilename=$_[1];
    my $timestamp=$_[2];
    my $filecreatime=$_[3];
    my $fsize=$_[4];
    (my $fileonly,my $filedir,my $fileext) = fileparse($currentfilename, qr/\.[^.]*/);
    print "Path: $filedir, Name: $fileonly\n";
    
    my $filetp=get_filetype($conn,$fileext);
    my $filetypeid=$$filetp{'id'};
    my $filetypename=$$filetp{'filetypeshort'};
    print "Extension: $fileext -> Type: $filetypename\n";
    
    (my $merger_n, my $run_n, my $burst_n)=get_fileinfo($fileonly);
    print "Merger: $merger_n, Run: $run_n, Burst: $burst_n\n\n"; 
    my $isdebug=0;
    if ($merger_n==0){
	$isdebug=1;
    }    
    update_run($conn,$run_n,$timestamp,$filetypeid);
    if ($filedir eq ($datadir."/")){
	
    }else{
	print "ERROR: current data dir: $datadir NOT MATCHING with $filedir for file $fileonly$fileext\n\n";
    }
    
    my $fileuri="file://".$thishost.$currentfilename;
    
    eval { 
	insert_file($conn,$fileonly,"1",$timestamp,$filetypeid,$run_n,$burst_n);
    }; warn "Error in inserting new UNIQUE record in FILE table" if $@;

    my $trun=get_run($conn,$run_n);
    my $run_id=$$trun{'id'};
    
    eval { 
	update_burst($conn,$burst_n,$isdebug,$timestamp,$run_id,$run_n);
    }; warn "Error in inserting new UNIQUE record in FILECOPY table" if $@;   

    eval { 
	insert_filecopy($conn,$fileonly,$fileuri,$filecreatime,$fsize);
    }; warn "Error in inserting new UNIQUE record in FILECOPY table" if $@;   
} 

